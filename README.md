# astrometry.js
Extract star pixel coordinates from a FITS image using JavaScript (supported on Node.js and your Browser)

## image2xy

A port of the blind image2xy solver utility from [astrometry.net](http://astrometry.net/) using [Emscripten](http://emscripten.org).

----------------------------------------------------------

#### Install <small>(Node.js)</small>

```
npm install astrometry.js
```

#### Usage

Read a FITS image file into a buffer (or `Uint8Array` in the browser, see browser example below))

``` js
const fs = require('fs');
const buf = fs.readFileSync('./example.fits');

const image2xy = require('astrometry.js').image2xy;

const result = image2xy(buf, { verbose: true, extension: 0 });
```

----------------------------------------------------------


#### Install <small>(Browser)</small>

``` html
<script src="https://cdn.jsdelivr.net/npm/astrometry.js"></script>
```

#### Usage

You'll need to do a little bit of work to get a file buffer on the browser. Live [example](https://jsfiddle.net/cj5sf2h2/17/).

``` js
var reader = new FileReader();

reader.onload = function (e) {
    // Get the image file as a buffer
    var buf = new Uint8Array(e.currentTarget.result);

    // Get a fits file buffer containing a star list
    const results = astrometry(buf, { verbose: true, extension: 0 });
};

reader.readAsArrayBuffer(file);
```

----------------------------------------------------------


### Example

The following shows an example output.

``` js
const result = image2xy(buf, { verbose: true, extension: 0 });

>   infile=fits_buf.fits
    outfile=fits_buf.xy.fits
    nhdus=1
    Got naxis=2, na1=4096, na2=4096
    simplexy: nx=4096, ny=4096
    simplexy: dpsf=1.000000, plim=8.000000, dlim=1.000000, saddle=5.000000
    simplexy: maxper=1000, maxnpeaks=10000, maxsize=2000, halfbox=100
    simplexy: median smoothing...
    simplexy: measuring image noise (sigma)...
    Sampling sigma at 42025 points
    Nsigma=0.7, s=13.132
    simplexy: found sigma=13.132.
    simplexy: finding objects...
    simplexy: found 734 blobs
    simplexy: finding peaks...
    simplexy: found 743 sources.
```

### Options

You may use the same options that image2xy supports by providing the flags directly, or you may use the following human friendly versions.

##### Options List

|Option|Flag|Type|Description|
|------|----|----|-----------|
|**help**|'h'| boolean | Print available options and usage instructions|
|**verbose**|'v'| boolean | Print verbose messages|
|**extension**|'e'| number | Read from a single FITS extension|
|**downsampleFactor**|'D'| number | Downsample, if necessary, by this many factors of two|
|**medianFilteringScale**|'s'| number | Set median-filter box size (default 100 pixels)|
|**psfWidth**|'w'| number | Set Gaussian PSF sigma (default 1 pixel)|
|**noiseLevel**|'g'| number | Set image noise level|
|**peakSigma**|'p'| number | Set significance level of peaks (default 8 sigmas)|
|**saddleLevel**|'a'| number | Set saddle level joining peaks (default 5 sigmas)|
|**disableBackgroundSubtraction**|'b'| boolean |Don't do (median-based) background subtraction|
|**backgroundLevel**|'G'| number | Subtract this 'global' background value; implies -b|
|**outputFilename**|'o'| filename  | Write XYlist to given filename.|
|**backgroundSubtractedImageName**|'S'| filename  | Save background-subtracted image to this filename (FITS float image)|
|**backgroundImageName**|'B'| filename  | Save background image to filename|
|**smoothedImageName**|'U'| filename | Save smoothed background-subtracted image to filename|
|**maskImageName**|'M'| filename | Save mask image to filename|
|**blobImageName**|'C'| filename | Save connected-components image to filename|
