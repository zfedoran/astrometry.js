/*
# This file is part of the Astrometry.net suite.
# Licensed under a 3-clause BSD style license - see LICENSE
*/

#include <string.h>
#include <stdio.h>
#include <unistd.h>
#include <assert.h>
#include <sys/types.h>
#include <unistd.h>
#include <math.h>
#include <float.h>

#include "os-features.h"
#include "image2xy.h"
#include "ioutils.h"
#include "simplexy.h"
#include "dimage.h"
#include "errors.h"
#include "log.h"
#include "mathutil.h"
#include "lodepng.h"

static void write_png(const char *filename, float *image, unsigned width, unsigned height, int npeaks, float *xlist, float *ylist) {
	unsigned char *png_img = malloc(width * height * 4);

	unsigned x, y;
	for (y = 0; y < height; y++)
		for (x = 0; x < width; x++) {
			unsigned char val = (unsigned char)(image[width * y + x] * 255);

			png_img[4 * width * y + 4 * x + 0] = val;
			png_img[4 * width * y + 4 * x + 1] = val;
			png_img[4 * width * y + 4 * x + 2] = val;
			png_img[4 * width * y + 4 * x + 3] = 255;
		}

	int i;
	for (i = 0; i < npeaks; i++) {
		x = (unsigned)(xlist[i] + 0.5);
		y = (unsigned)(ylist[i] + 0.5);

		png_img[4 * width * y + 4 * x + 0] = 255;
		png_img[4 * width * y + 4 * x + 1] = 0;
		png_img[4 * width * y + 4 * x + 2] = 0;
		png_img[4 * width * y + 4 * x + 3] = 255;
	}

	unsigned error = lodepng_encode32_file(filename, png_img, width, height);

	if (error)
		printf("error %u: %s\n", error, lodepng_error_text(error));

	free(png_img);
}

static float* upconvert(unsigned char* u8,
                        int nx, int ny) {
    int i;
    float* f = malloc(nx * ny * sizeof(float));
    if (!f) {
        SYSERROR("Failed to allocate image array to upconvert u8 image to floating-point.");
        return NULL;
    }
    for (i=0; i<(nx*ny); i++)
        f[i] = u8[i];
    return f;
}

static void rebin(float** thedata,
                  int W, int H, int S,
                  int* newW, int* newH) {
    float sigma = S;

	get_output_image_size(W, H, S, EDGE_AVERAGE, newW, newH);

    // Gaussian smooth in-place.
    dsmooth2(*thedata, W, H, sigma, *thedata);

    // Average SxS blocks, placing the result in the bottom (newW * newH) first pixels.
	if (!average_image_f(*thedata, W, H, S, EDGE_AVERAGE, newW, newH, *thedata)) {
		ERROR("Averaging the image failed.");
		return;
	}
}

int image2xy_run(simplexy_t* s,
				 int downsample, int downsample_as_required) {
	int newW, newH;
	anbool free_fimage = FALSE;
	// the factor by which to downsample.
	int S = downsample ? downsample : 1;
	int jj;
    anbool tryagain;
    int rtn = -1;

	if (downsample && downsample > 1) {
		logmsg("Downsampling by %i...\n", S);
        if (!s->image) {
            s->image = upconvert(s->image_u8, s->nx, s->ny);
            free_fimage = TRUE;
        }
		if (!s->image)
			goto bailout;
		rebin(&s->image, s->nx, s->ny, S, &newW, &newH);
		s->nx = newW;
		s->ny = newH;
	}

	do {
		simplexy_run(s);

		tryagain = FALSE;
		if (s->npeaks == 0 &&
			downsample_as_required) {
			logmsg("Downsampling by 2...\n");
			if (s->image_u8) {
				s->image = upconvert(s->image_u8, s->nx, s->ny);
				if (!s->image)
					goto bailout;
				free_fimage = TRUE;
				s->image_u8 = NULL;
			}
			rebin(&s->image, s->nx, s->ny, 2, &newW, &newH);
			s->nx = newW;
			s->ny = newH;
			S *= 2;
			tryagain = TRUE;
			downsample_as_required--;
		}

		if (!tryagain && s->image) {
			write_png("debug-image.png", s->image, s->nx, s->ny, s->npeaks, s->x, s->y);
		}

	} while (tryagain);


	for (jj=0; jj<s->npeaks; jj++) {
		assert(isfinite((s->x)[jj]));
		assert(isfinite((s->y)[jj]));
		// shift the origin to the FITS standard: 
		// center of the lower-left pixel is (1,1).
		(s->x)[jj] = ((s->x)[jj] + 0.5) * (double)S + 0.5;
		(s->y)[jj] = ((s->y)[jj] + 0.5) * (double)S + 0.5;
	}

	dselip_cleanup();
    rtn = 0;
 bailout:
	if (free_fimage) {
		free(s->image);
        s->image = NULL;
    }
	return rtn;
}

