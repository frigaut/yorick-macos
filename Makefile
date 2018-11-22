# Makefile to build yorick and the main plugins on OSX.
# change the variables below to suit your install:
# These 2 below allows to build for 10.5 and 10.6 SDKs:
# HAVE_XFT for XFT (duh)
# X11_SDK=/Developer/SDKs/MacOSX10.6.sdk/usr/X11/lib/
# X11_SDK=/usr/X11/lib/
# X11_SDK=/opt/X11/lib/
X11_SDK=/opt/X11/lib/

# the following line for XFT too:
# X11_INC=-I/usr/X11R6/include -I/usr/X11R6/include/freetype2
X11_INC=-I/opt/X11/include -I/opt/X11/include/freetype2
X11_LIB=-lXft -lfontconfig

# X11_INC=-I/opt/X11/include
# X11_LIB=-I/opt/X11/lib

# OSX_SDK=/Developer/SDKs/MacOSX10.6.sdk
OSX_FLAGS=-DHAVE_XFT -D_FORTIFY_SOURCE=0
# to get -O2, use:
# CFLAGS=-O2 make [all,plugins,yorick]
# -j -mmacosx-version-min=10.5 -with-macos-sdk=$(OSX_SDK)
# This is the path of the external libraries (fftw3, hdf5, ...)
# for macport, it is /opt/local/, for fink, /sw
EXT_PREFIX=/opt/local
# yorick version (to substitute in installer readme text)
YORICK_VERSION=2.2
# Python version that has gtk to run yorick GUIs
PY_VERSION=2.7

# Do not change below:
# yorick is build relocatable:
YORICK=$(PWD)/yorick/relocate/bin/yorick
# build date
BUILD_DATE=$(shell date)
#YORICK_PKG_VERSION=2
YORICK_PKG_VERSION=$(shell echo `cat .yorick_pkg_version`+1 | /usr/bin/bc)

env:
	@echo yorick version = $(YORICK_VERSION)
	@echo package version = $(YORICK_PKG_VERSION)
	@echo root for external libraries/includes = $(EXT_PREFIX)
	@echo python version for gtk = $(PY_VERSION)
	@sleep 2

# the following function update the local git repo if it exists,
# otherwise it clones it from the main repo
init_update_git =                                       \
	cd plugins;                                           \
	if [ -d $(1) ]; then cd $(1); git pull origin master; \
	else git clone git://github.com/$(2)/$(1).git; fi

# Targets:
# make clean to remove all directories to start from scratch
# make all to build everything
# make yorick to update/build yorick
# make plugins to update/build all plugins
# make plugin_name to update/build "plugin_name"
# make install to copy the yorick/relocate to ./yorick-2.2,
#  in prep for packaging and will run apple's packagemaker
#  using yorick/pmdoc as package definition resources

all: env
	$(MAKE) yorick
	$(MAKE) plugins
	$(MAKE) install

yorick: env
	@echo "Building yorick"
	if [ -d yorick ]; then cd yorick; git pull origin master; \
	else git clone git://github.com/dhmunro/yorick.git; fi
	@cd yorick; make config
	# to get a yorick build on lion compatible with 10.5, we need to play a few tricks:
	# the problem here is with libX11.dylib.
	@cd yorick; sed -i '' -E 's|^Y_CFLAGS=(.*)|Y_CFLAGS=$(OSX_FLAGS) |' Make.cfg
	@cd yorick; sed -i '' -E 's|^XLIB=(.*)|XLIB=-L$(X11_SDK) |' Make.cfg
	@cd yorick; sed -i '' -E 's|^X11LIB=(.*)|X11LIB=\1 $(X11_LIB) |' Make.cfg
	@cd yorick; sed -i '' -E 's|^XINC=(.*)|XINC=$(X11_INC) |' Make.cfg
	# end of back compatibility tricks
	# get the xft patch
	@cd yorick; wget --no-check-certificate https://rawgit.com/frigaut/frigaut-arch-abs-files/master/yorick-git-xft.patch
	#wget http://www.maumae.net/yorick/packages/src/yorick-git-xft.patch
	@cd yorick; patch -p1 < yorick-git-xft.patch
	# @cd yorick/yorick; sed -i '' -E 's|strncpy\(node|memcpy\(node|' codger.c
	@cd yorick; make; make install
	cp -p ./scripts/rlwrap yorick/relocate/bin/.
	cp -p ./scripts/yorick.install yorick/relocate/bin/.
	export PATH=`pwd`/yorick/relocate/bin:${PATH}
	echo ${PATH}
	which yorick

install: env
	-rm -rf yorick-$(YORICK_VERSION) yorick.pmdoc
	cp -pr yorick/relocate yorick-$(YORICK_VERSION)
	# Packaging:
	cp -pr yorick.pmdoc.template yorick.pmdoc;
	cd yorick.pmdoc; \
	sed -i '' -E 's|<version>(.*)</version>|<version>$(YORICK_PKG_VERSION)</version>|' 01yorick.xml;\
	sed -i '' -E 's|yorick_version|yorick-$(YORICK_VERSION)|' *; \
	sed -i '' -E 's|yorick_pkg_date|$(BUILD_DATE)|' *;
	/Developer/usr/bin/packagemaker --doc yorick.pmdoc --verbose --no-recommend \
	 --version $(YORICK_PKG_VERSION) --out packages/yorick-$(YORICK_VERSION).$(YORICK_PKG_VERSION).pkg
	@echo $(YORICK_PKG_VERSION) > .yorick_pkg_version
	@echo Package saved in packages/yorick-$(YORICK_VERSION).$(YORICK_PKG_VERSION).pkg
	cd packages; cp -p yorick-$(YORICK_VERSION).$(YORICK_PKG_VERSION).pkg yorick-latest.pkg
	ncftpput maumae www/yorick/mac packages/yorick-$(YORICK_VERSION).$(YORICK_PKG_VERSION).pkg
	ncftpput maumae www/yorick/mac packages/yorick-latest.pkg
# /Developer/usr/bin/packagemaker --root yorick-$(YORICK_VERSION) --no-recommend \
#   --id yorick.github.com --version $(YORICK_PKG_VERSION) --title yorick \
#   --verbose --target 10.5 --no-relocate --resources Resources \
#   --out yorick-$(YORICK_VERSION).$(YORICK_PKG_VERSION).pkg

clean:
	-rm -rf yorick plugins yorick-$(YORICK_VERSION) yorick.pmdoc

plugins: FORCE
	mkdir -p plugins
	$(MAKE) yutils imutil soy yao ml4 opra spydr hdf5 mpeg z svipc usleep yeti

FORCE:

make_plug:
	cd plugins/$(PLUG_DIR); \
	sed -i '' -E 's|/usr/bin/env python$$|/usr/bin/env python$(PY_VERSION)|' *.py; \
	$(YORICK) -batch make.i; make clean; make; make install

# PLUGINS, one by one:
yutils: env
	$(call init_update_git,yorick-yutils,frigaut)
	$(MAKE) make_plug PLUG_DIR=yorick-yutils

imutil: env
	$(call init_update_git,yorick-imutil,frigaut)
	cd plugins/yorick-imutil; $(YORICK) -batch make.i; make clean; \
	 make TGT=exe install-exe; make install

soy: env
	$(call init_update_git,yorick-soy,frigaut)
	$(MAKE) make_plug PLUG_DIR=yorick-soy

yao: env
	$(call init_update_git,yao,frigaut)
	cd plugins/yao; cp Makefile.template Makefile
	cd plugins/yao; sed -i '' -E 's|^PKG_DEPLIBS=(.*)|PKG_DEPLIBS=$(EXT_PREFIX)/lib/libfftw3f.a |' Makefile
	cd plugins/yao; sed -i '' -E 's|^PKG_CFLAGS=(.*)|PKG_CFLAGS=-I$(EXT_PREFIX)/include |' Makefile
	$(MAKE) make_plug PLUG_DIR=yao

ml4: env
	$(call init_update_git,yorick-ml4,frigaut)
	$(MAKE) make_plug PLUG_DIR=yorick-ml4

opra: env
	$(call init_update_git,yorick-opra,frigaut)
	cd plugins/yorick-opra; git checkout opra-tomo
	rm -rf yorick/relocate/share/opra
	$(MAKE) make_plug PLUG_DIR=yorick-opra

spydr: env
	$(call init_update_git,yorick-spydr,frigaut)
	$(MAKE) make_plug PLUG_DIR=yorick-spydr


hdf5: env
	$(call init_update_git,yorick-hdf5,frigaut)
	cd plugins/yorick-hdf5; sed -i '' -E 's|PKG_DEPLIBS=(.*)|PKG_DEPLIBS=-lz $(EXT_PREFIX)/lib/libhdf5.a |' Makefile
	cd plugins/yorick-hdf5; sed -i '' -E 's|PKG_CFLAGS=(.*)|PKG_CFLAGS=-I$(EXT_PREFIX)/include -D H5_USE_16_API |' Makefile
	$(MAKE) make_plug PLUG_DIR=yorick-hdf5

mpeg: env
	$(call init_update_git,yorick-mpeg,dhmunro)
	cd plugins/yorick-mpeg; $(YORICK) -batch make.i
	cd plugins/yorick-mpeg; sed -i '' -E 's|#undef HAVE_OSX|#define HAVE_OSX 1 |' config.h
	$(MAKE) make_plug PLUG_DIR=yorick-mpeg

z: env
	$(call init_update_git,yorick-z,dhmunro)
	cd plugins/yorick-z; ./configure
	cd plugins/yorick-z; \
	echo "PKG_I=zlib.i png.i jpeg.i" > Makeyorz; \
	echo "PKG_I=zlib.i png.i jpeg.i" >> Makeyorz; \
	echo "OBJS=yzlib.o spng.o ypng.o yjpeg.o" >> Makeyorz; \
	echo "PKG_DEPLIBS=-L/opt/local/lib/ -lz $(EXT_PREFIX)/lib/libpng.a $(EXT_PREFIX)/lib/libjpeg.a" >> Makeyorz; \
	echo "PKG_I_START=yorz.i" >> Makeyorz; \
	echo "ZLIB_INC=" >> Makeyorz; \
	echo "PNG_INC=-I$(EXT_PREFIX)/include" >> Makeyorz; \
	echo "JPEG_INC=-I$(EXT_PREFIX)/include" >> Makeyorz; \
	echo "AVCODEC_INC=" >> Makeyorz;
	$(MAKE) make_plug PLUG_DIR=yorick-z

svipc: env
	$(call init_update_git,yp-svipc,frigaut)
	cd plugins/yp-svipc/yorick; $(YORICK) -batch make.i; make clean; make install

usleep: env
	$(call init_update_git,yorick-usleep,frigaut)
	$(MAKE) make_plug PLUG_DIR=yorick-usleep

yeti: env
	cd plugins; wget http://cral.univ-lyon1.fr/labo/perso/eric.thiebaut/downloads/yorick/yeti-6.3.3.tar.bz2
	#cd plugins; wget http://www-obs.univ-lyon1.fr/labo/perso/eric.thiebaut/files/yeti-6.3.2.tar.bz2
	cd plugins; bunzip2 yeti-6.3.3.tar.bz2; tar xvf yeti-6.3.3.tar
	cd plugins/yeti-6.3.3; ./configure --yorick=$(YORICK)
	#yeti_rgl ne compile pas correctement. Le compiler sans optimisation (pas de -O).
	#cd plugins/yeti-6.3.3/yeti; sed -i '' -E 's|\$\(CFLAGS\) -DYORICK|\$\(CFLAGS\) -O0 -DYORICK |' Makefile
	cd plugins/yeti-6.3.3; make clean; make all; make install
