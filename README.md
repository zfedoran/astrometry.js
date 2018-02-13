# astrometry.js - image2xy
Extract star pixel coordinates from a FITS image using JavaScript (supported on Node.js and your Browser)

This project is a port of the blind image2xy solver utility from [Astrometry.net](http://astrometry.net/) using [Emscripten](http://emscripten.org).

### Install:

#### Node.js

```
npm install astrometry
```

#### Browser

``` html
<script src="https://cdn.jsdelivr.net/npm/astrometry"></script>
```

### Usage (Node.js)

Read a FITS image file into a buffer (or `Uint8Array` in the browser, see browser example below))

``` js
const fs = require('fs');
const buf = fs.readFileSync('./example.fits');

const image2xy = require('astrometry').image2xy;

const result = image2xy(buf, { verbose: true, extension: 0 });
```

### Usage (Browser)

You'll need to do a little bit of work to get a file buffer on the browser. 

``` js
var reader = new FileReader();

reader.onload = function (e) {
    // Get the image file as a buffer
    var buf = new Uint8Array(e.currentTarget.result);

    // Get a fits file buffer containing a star list
    const results = astrometry.image2xy(buf, { verbose: true, extension: 0 });
};

reader.readAsArrayBuffer(file);
```

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
    Failed to find (5x5) centroid of peak 0, subpeak 0 at (2,4)
    Failed to find (5x5) centroid of peak 4, subpeak 0 at (4093,6)
    Failed to find (5x5) centroid of peak 6, subpeak 0 at (29,12)
    Failed to find (3x3) centroid of peak 76, subpeak 0 at (1,359), and too close to edge for 5x5
    Failed to find (5x5) centroid of peak 92, subpeak 0 at (4085,479)
    Failed to find (5x5) centroid of peak 100, subpeak 0 at (3598,530)
    Failed to find (5x5) centroid of peak 172, subpeak 0 at (22,960)
    Failed to find (5x5) centroid of peak 178, subpeak 0 at (2007,992)
    Failed to find (5x5) centroid of peak 299, subpeak 0 at (2951,1595)
    Failed to find (5x5) centroid of peak 329, subpeak 0 at (8,1802)
    Failed to find (5x5) centroid of peak 346, subpeak 0 at (321,1918)
    Failed to find (5x5) centroid of peak 389, subpeak 0 at (1681,2118)
    Failed to find (5x5) centroid of peak 403, subpeak 0 at (772,2199)
    Failed to find (5x5) centroid of peak 410, subpeak 0 at (768,2208)
    Failed to find (5x5) centroid of peak 428, subpeak 0 at (44,2287)
    Failed to find (5x5) centroid of peak 434, subpeak 0 at (2,2317)
    Failed to find (5x5) centroid of peak 468, subpeak 0 at (756,2574)
    Failed to find (5x5) centroid of peak 531, subpeak 0 at (940,3038)
    Failed to find (5x5) centroid of peak 570, subpeak 0 at (1132,3247)
    Failed to find (3x3) centroid of peak 573, subpeak 1 at (1525,3248), and too close to edge for 5x5
    Failed to find (5x5) centroid of peak 629, subpeak 0 at (4092,3566)
    Failed to find (5x5) centroid of peak 675, subpeak 0 at (1921,3846)
    Failed to find (3x3) centroid of peak 733, subpeak 0 at (2743,4094), and too close to edge for 5x5
    simplexy: found 743 sources.
```

### Options

You may use the same options that image2xy supports by providing the flags directly, or you may use the following human friendly versions.

##### Options List

|Option|Flag|Type|Description|
|------|----|-----------|
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