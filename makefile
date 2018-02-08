CC=clang

SRCDIR  = src
OBJDIR  = bin

AN_GIT_REVISION ?= $(shell git describe)
AN_GIT_DATE ?= $(shell git log -n 1 --format=%cd | sed 's/ /_/g')
AN_GIT_URL := https://github.com/dstndstn/astrometry.net

CFLAGS_DEF += -DAN_GIT_REVISION='"$(AN_GIT_REVISION)"'
CFLAGS_DEF += -DAN_GIT_DATE='"$(AN_GIT_DATE)"'
CFLAGS_DEF += -DAN_GIT_URL='"$(AN_GIT_URL)"'
CFLAGS_DEF += -DHAVE_UNION_SEMUN

CFITSIO = $(SRCDIR)/cfitsio
ZLIB = $(SRCDIR)/cfitsio/zlib
ASTROMETRY = $(SRCDIR)/astrometry

CFLAGS =-c -Wall \
	-I$(ASTROMETRY)/blind \
	-I$(ASTROMETRY)/include \
	-I$(ASTROMETRY)/include/astrometry \
	-I$(ASTROMETRY)/util \
	-I$(ASTROMETRY)/qfits-an \
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

ASTROMETRY_SRC := $(addprefix $(ASTROMETRY)/, blind/image2xy-files.c blind/image2xy-main.c)

SRCS := $(CFITSIO_SRC) $(ZLIB_SRC) $(ASTROMETRY_SRC)
OBJS := $(patsubst %.c,$(OBJDIR)/%.o,$(SRCS))

$(OBJDIR)/%.o: %.c
	@mkdir -p $(@D)
	$(CC) $< -o $@ $(CFLAGS)

all: $(OBJS)

clean:
	$(RM) $(OBJS)

