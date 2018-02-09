CC=clang

SRCDIR  = src
OBJDIR  = bin

#AN_GIT_REVISION ?= $(shell git describe)
AN_GIT_REVISION ?= v0.0.1
AN_GIT_DATE ?= $(shell git log -n 1 --format=%cd | sed 's/ /_/g')
AN_GIT_URL := https://github.com/dstndstn/astrometry.net

CFLAGS_DEF += -DAN_GIT_REVISION='"$(AN_GIT_REVISION)"'
CFLAGS_DEF += -DAN_GIT_DATE='"$(AN_GIT_DATE)"'
CFLAGS_DEF += -DAN_GIT_URL='"$(AN_GIT_URL)"'
CFLAGS_DEF += -DHAVE_UNION_SEMUN -DHAVE_NET_SERVICES
CFLAGS_DEF += -DDONT_INCLUDE_OS_FEATURES_CONFIG_H -DNEED_QSORT_R=0 -DNEED_CANONICALIZE_FILE_NAME=1

CFITSIO = $(SRCDIR)/cfitsio
ZLIB = $(SRCDIR)/cfitsio/zlib
ASTROMETRY = $(SRCDIR)/astrometry

CFLAGS = -Wall \
	-I$(SRCDIR)/ \
	-I$(ASTROMETRY)/blind \
	-I$(ASTROMETRY)/include \
	-I$(ASTROMETRY)/include/astrometry \
	-I$(ASTROMETRY)/util \
	-I$(ASTROMETRY)/qfits-an \
	-I$(ASTROMETRY)/libkd \
	-I$(CFITSIO) \
	-I$(ZLIB) \
	$(CFLAGS_DEF)

CFITSIO_SRC := $(addprefix $(CFITSIO)/, buffers.c cfileio.c checksum.c \
	drvrfile.c drvrmem.c drvrnet.c drvrsmem.c drvrgsiftp.c editcol.c edithdu.c \
	eval_l.c eval_y.c eval_f.c fitscore.c getcol.c getcolb.c getcold.c getcole.c \
	getcoli.c getcolj.c getcolk.c getcoll.c getcols.c getcolsb.c getcoluk.c \
	getcolui.c getcoluj.c getkey.c group.c grparser.c histo.c iraffits.c modkey.c \
	putcol.c putcolb.c putcold.c putcole.c putcoli.c putcolj.c putcolk.c \
	putcoluk.c putcoll.c putcols.c putcolsb.c putcolu.c putcolui.c putcoluj.c \
	putkey.c region.c scalnull.c swapproc.c wcssub.c wcsutil.c imcompress.c \
	quantize.c ricecomp.c pliocomp.c fits_hcompress.c fits_hdecompress.c \
	simplerng.c f77_wrap1.c f77_wrap2.c f77_wrap3.c f77_wrap4.c)

ZLIB_SRC := $(addprefix $(ZLIB)/, zuncompress.c zcompress.c \
	adler32.c crc32.c inffast.c inftrees.c trees.c \
	zutil.c deflate.c infback.c inflate.c uncompr.c)

ASTROMETRY_SRC := $(addprefix $(ASTROMETRY)/qfits-an/, anqfits.c md5.c \
	qfits_byteswap.c qfits_card.c qfits_convert.c qfits_error.c qfits_float.c \
	qfits_header.c qfits_image.c qfits_md5.c qfits_memory.c qfits_rw.c \
	qfits_table.c qfits_time.c qfits_tools.c)

ASTROMETRY_SRC += $(addprefix $(ASTROMETRY)/util/, bl.c bt.c an-endian.c \
	ctmf.c tic.c dallpeaks.c dcen3x3.c dfind.c dmedsmooth.c dobjects.c dpeaks.c \
	dselip.c dsigma.c dsmooth.c eigen-math-c.c errors.c fitsfile.c fitsioutils.c \
	fitstable.c image2xy.c ioutils.c log.c mathutil.c os-features.c \
	permutedsort.c resample.c simplexy.c starutil.c starxy.c tabsort.c xylist.c)

ASTROMETRY_SRC += $(addprefix $(ASTROMETRY)/, blind/image2xy-files.c blind/image2xy-main.c)

SRCS := $(ZLIB_SRC) $(CFITSIO_SRC) $(ASTROMETRY_SRC)
OBJS := $(patsubst %.c,$(OBJDIR)/%.o,$(SRCS))

$(OBJDIR)/%.o: %.c
	@mkdir -p $(@D)
	$(CC) -c $< -o $@ $(CFLAGS)

image2xy: $(OBJS)
	$(CC) $(CFLAGS) -o image2xy $(OBJS)

clean:
	$(RM) $(OBJS)

