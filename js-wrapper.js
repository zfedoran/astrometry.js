/*
Usage: image2xy [options] fitsname.fits

Read a FITS file, find objects, and write out
X, Y, FLUX to   fitsname.xy.fits .

   [-e <extension>]: read from a single FITS extension
   [-O]  overwrite existing output file.
   [-o <output-filename>]  write XYlist to given filename.
   [-L <Lanczos-order>]
   [-8]  don't use optimization for byte (u8) images.
   [-H]  downsample by a factor of 2 before running simplexy.
   [-d <downsample-factor>]  downsample by an integer factor before running simplexy.
   [-D <downsample-factor>] downsample, if necessary, by this many factors of two.
   [-s <median-filtering scale>]: set median-filter box size (default 100 pixels)
   [-w <PSF width>]: set Gaussian PSF sigma (default 1 pixel)
   [-g <sigma>]: set image noise level
   [-p <sigmas>]: set significance level of peaks (default 8 sigmas)
   [-a <saddle-sigmas>]: set "saddle" level joining peaks (default 5 sigmas)
   [-P <image plane>]: pull out a single plane of a multi-color image (default: first plane)
   [-b]: don't do (median-based) background subtraction
   [-G <background>]: subtract this 'global' background value; implies -b
   [-m]: set maximum extended object size for deblending (default 2000 pixels)

   [-S <background-subtracted image>]: save background-subtracted image to this filename (FITS float image)
   [-B <background image>]: save background image to filename
   [-U <smoothed background-subtracted image>]: save smoothed background-subtracted image to filename
   [-M <mask image>]: save mask image to filename
   [-C <blob-image>]: save connected-components image to filename

   [-v] verbose - repeat for more and more verboseness

   image2xy 'file.fits[1]'   - process first extension.
   image2xy 'file.fits[2]'   - process second extension
   image2xy file.fits+2      - same as above
*/

const EM_IMAGE2XY_OPTIONS = {
    help: 'h',                             //<boolean>  Print available options and usage instructions
    verbose: 'v',                          //<boolean>  Print verbose messages

    extension: 'e',                        //<number>   Read from a single FITS extension
    downsampleFactor: 'D',                 //<number>   Downsample, if necessary, by this many factors of two
    medianFilteringScale: 's',             //<number>   Set median-filter box size (default 100 pixels)
    psfWidth: 'w',                         //<number>   Set Gaussian PSF sigma (default 1 pixel)
    noiseLevel: 'g',                       //<number>   Set image noise level
    peakSigma: 'p',                        //<number>   Set significance level of peaks (default 8 sigmas)
    saddleLevel: 'a',                      //<number>   Set saddle level joining peaks (default 5 sigmas)
    disableBackgroundSubtraction: 'b',     //<boolean>  Don't do (median-based) background subtraction
    backgroundLevel: 'G',                  //<number>   Subtract this 'global' background value; implies -b

    outputFilename: 'o',                   //<filename> Write XYlist to given filename.
    backgroundSubtractedImageName: 'S',    //<filename> save background-subtracted image to this filename (FITS float image)
    backgroundImageName: 'B',              //<filename> save background image to filename
    smoothedImageName: 'U',                //<filename> save smoothed background-subtracted image to filename
    maskImageName: 'M',                    //<filename> save mask image to filename
    blobImageName: 'C'                     //<filename> save connected-components image to filename
}

var Module = Object.assign((Module || {}), {
    preRun: function() {
        // Override the default output location so that we can return it.
        const stdout_list = [];
        Module.print = function(msg) { console.log(msg); stdout_list.push(msg); }
        Module.exit = function() { }

        Module.image2xy = function (fits_file, options) {
            // We need a fits file buffer to do anything useful
            if (!fits_file) {
                console.log('image2xy: No fits file buffer provided.');
            }

            // Convert options to image2xy formatted options object
            if (options) {
                options = Object.assign({}, options);

                Object.keys(options).forEach(function(name) {
                    if (EM_IMAGE2XY_OPTIONS[name]) {
                        options[EM_IMAGE2XY_OPTIONS[name]] = options[name];
                        delete options[name];
                    }
                })
            }

            // Create a workspace directory in the emscripten virtual file system and go to it
            FS.mkdir('/workspace');
            FS.chdir('/workspace');

            // Link a filename to a buffer (helper method)
            function add_to_memfs(name, buf) {
                // Buffers are not copied by emscripten, this is not actually a
                // write but simply creates a reference to the buffer in MEMFS.
                const stream = FS.open(name, 'w+');
                FS.write(stream, buf, 0, buf.length, 0, true);
                FS.close(stream);
            }

            // Build the arguments array for the main() method
            var args = [];
            if (options) {

                // Create the arguments list for main() method
                for (var prop in options) {
                    const val = options[prop];
                    if (val !== undefined) {
                        // Handle boolean flags that don't need values
                        if (prop.match(/[O 8 H b v]/) && val) {
                            args.push('-' + prop);
                            continue;
                        }

                        // Add the flag (followed by a value)
                        args.push('-' + prop);

                        // Handle inputs that are not boolean or buffers
                        if (prop.match(/[e o L d D s w g p a P G m S B U M C]/)) {
                            // Split the value into an array, and concat with the args
                            args = args.concat(val.toString().split(/\s/));
                        }
                    }
                }
            }

            // Add the FITS file to the args list
            if (fits_file) {
                add_to_memfs('fits_buf.fits', fits_file);
                args.push('fits_buf.fits');
            } 

            // Clear the stdout_list (in case this function was called again)
            //stdout_list.length = 0;
            run(args);

            // Remove the source image from the workspace
            if (fits_file) {
                FS.unlink('fits_buf.fits');
            }

            // Get the output files and remove the workspace from the virtual file system
            var num_files = 0;
            const output_files = {};
            const workspace = FS.readdir('/workspace');
            for (var index in workspace) {
                const name = workspace[index];
                if (name !== '.' && name !== '..') {
                    output_files[name] = FS.readFile(name, { encoding: 'binary' });
                    FS.unlink(name);
                    num_files++;
                }
            }

            // Clean up the virtual file system in case of re-entry
            FS.chdir('/');
            FS.rmdir('/workspace');

            if (num_files === 1) {
                return Object.values(output_files).pop();
            }
            if (num_files > 1) {
                return output_files;
            }

            return stdout_list.join('\n');
        }

        // Wrapper for invoking main() method
        function run(args) {
            args = args || [];

            ensureInitRuntime();

            var argc = args.length + 1;
            var argv = [allocate(intArrayFromString(Module['thisProgram']), 'i8', ALLOC_NORMAL),0,0,0];
            for (var i = 0; i < argc - 1; i = i + 1) {
                argv = argv.concat([allocate(intArrayFromString(args[i]), 'i8', ALLOC_NORMAL), 0,0,0]);
            }
            argv.push(0);
            argv = allocate(argv, 'i32', ALLOC_NORMAL);

            return Module['_main'](argc, argv, 0);
        }
    }
});