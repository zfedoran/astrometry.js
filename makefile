CC=emcc

SRCDIR  = src
OBJDIR  = bin
DISTDIR = dist

# Required for CFITSIO
CFLAGS_CFITSIO = \
	-DHAVE_UNION_SEMUN \
	-DHAVE_NET_SERVICES \
	-D__x86_64__

# Required for Astrometry
CFLAGS_ASTROMETRY = \
	-DDONT_INCLUDE_OS_FEATURES_CONFIG_H \
	-DNEED_QSORT_R=1 \
	-DNEED_DECLARE_QSORT_R=1 \
	-DNEED_CANONICALIZE_FILE_NAME=1 \
	-D_POSIX_SYNCHRONIZED_IO \
	-D__APPLE__ \
	-D__sun

CFLAGS_DEF = $(CFLAGS_CFITSIO) $(CFLAGS_ASTROMETRY)

# Include GIT information
AN_GIT_REVISION ?= v0.0.1
AN_GIT_DATE ?= $(shell git log -n 1 --format=%cd | sed 's/ /_/g')
AN_GIT_URL := https://github.com/zfedoran/astrometry.js

CFLAGS_DEF += -DAN_GIT_REVISION='"$(AN_GIT_REVISION)"'
CFLAGS_DEF += -DAN_GIT_DATE='"$(AN_GIT_DATE)"'
CFLAGS_DEF += -DAN_GIT_URL='"$(AN_GIT_URL)"'

# Prod
EMFLAGS = -O3

# Debug
# EMFLAGS = -O0 -s ASSERTIONS=1

# Emscripten Flags
EMFLAGS += \
	-s ALLOW_MEMORY_GROWTH=1 \
	-s TOTAL_MEMORY=134217728 \
	-s NO_EXIT_RUNTIME=1 \
	-s FORCE_FILESYSTEM=1 \
	-s EXPORT_NAME="'astrometry'" \
	-s NODEJS_CATCH_EXIT=1 \
	-s INVOKE_RUN=0 \
	-s MODULARIZE=1 \
	--memory-init-file 0 \
	--pre-js js-wrapper.js 

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
	$(CFLAGS_DEF) \
	$(EMFLAGS)

CFITSIO_SRC := $(addprefix $(CFITSIO)/, buffers.c cfileio.c checksum.c \
	drvrfile.c drvrmem.c drvrnet.c drvrsmem.c drvrgsiftp.c editcol.c edithdu.c \
	eval_l.c eval_y.c eval_f.c fitscore.c getcol.c getcolb.c getcold.c getcole.c \
	getcoli.c getcolj.c getcolk.c getcoll.c getcols.c getcolsb.c getcoluk.c \
	getcolui.c getcoluj.c getkey.c group.c grparser.c histo.c iraffits.c modkey.c \
	putcol.c putcolb.c putcold.c putcole.c putcoli.c putcolj.c putcolk.c \
	putcoluk.c putcoll.c putcols.c putcolsb.c putcolu.c putcolui.c putcoluj.c \
	putkey.c region.c scalnull.c swapproc.c wcssub.c wcsutil.c imcompress.c \
	quantize.c ricecomp.c pliocomp.c fits_hcompress.c fits_hdecompress.c \
	simplerng.c )

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

APP = $(DISTDIR)/astrometry.js

$(OBJDIR)/%.o: %.c
	@mkdir -p $(@D)
	$(CC) -c $< -o $@ $(CFLAGS)

$(APP): $(OBJS)
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -o $@ $(OBJS)
	@$(call make-module, $@)

all: $(APP)

clean:
	$(RM) $(OBJS)

define make-module
	echo 'if (astrometry) { const em_module = astrometry; astrometry = function() { return em_module().image2xy.apply(this, arguments); }; if (typeof module === "object" && module.exports) { module.exports = { image2xy: astrometry }; } }' >> $(1);
endef