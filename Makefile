OUT_ZIP=Alpine.zip
LNCR_EXE=Alpine.exe

DLR=curl
DLR_FLAGS=-L
BASE_URL=http://dl-cdn.alpinelinux.org/alpine/v3.9/releases/x86_64/alpine-minirootfs-3.9.2-x86_64.tar.gz
LNCR_ZIP_URL=https://github.com/yuk7/wsldl/releases/download/19031901/icons.zip
LNCR_ZIP_EXE=Alpine.exe

PLANTUML_URL=http://sourceforge.net/projects/plantuml/files/plantuml.jar/download
ACROTEX_URL=http://mirrors.ctan.org/macros/latex/contrib/acrotex.zip
INSTALL_PS_SCRIPT=https://raw.githubusercontent.com/binarylandscapes/AlpineWSL/master/install.ps1
FEATURE_PS_SCRIPT=https://raw.githubusercontent.com/binarylandscapes/AlpineWSL/master/addWSLfeature.ps1
wslGit=https://github.com/andy-5/wslgit/releases/download/v0.7.0/wslgit.exe

all: $(OUT_ZIP)

zip: $(OUT_ZIP)
$(OUT_ZIP): ziproot
	@echo -e '\e[1;31mBuilding $(OUT_ZIP)\e[m'
	cd ziproot; zip ../$(OUT_ZIP) *

ziproot: Launcher.exe rootfs.tar.gz ps_scripts wslGit
	@echo -e '\e[1;31mBuilding ziproot...\e[m'
	mkdir ziproot
	cp Launcher.exe ziproot/${LNCR_EXE}
	cp rootfs.tar.gz ziproot/
	cp install.ps1 ziproot/
	cp addWSLfeature.ps1 ziproot/
	cp wslgit.exe ziproot/

ps_scripts:
	$(DLR) $(DLR_FLAGS) $(INSTALL_PS_SCRIPT) -o install.ps1
	$(DLR) $(DLR_FLAGS) $(FEATURE_PS_SCRIPT) -o addWSLfeature.ps1

wslGit:
	$(DLR) $(DLR_FLAGS) $(wslGit) -o wslgit.exe

exe: Launcher.exe
Launcher.exe: icons.zip
	@echo -e '\e[1;31mExtracting Launcher.exe...\e[m'
	unzip icons.zip $(LNCR_ZIP_EXE)
	mv $(LNCR_ZIP_EXE) Launcher.exe

icons.zip:
	@echo -e '\e[1;31mDownloading icons.zip...\e[m'
	$(DLR) $(DLR_FLAGS) $(LNCR_ZIP_URL) -o icons.zip

rootfs.tar.gz: rootfs
	@echo -e '\e[1;31mBuilding rootfs.tar.gz...\e[m'
	cd rootfs; sudo tar -zcpf ../rootfs.tar.gz `sudo ls`
	sudo chown `id -un` rootfs.tar.gz

rootfs: base.tar.gz
	@echo -e '\e[1;31mBuilding rootfs...\e[m'
	mkdir rootfs
	sudo tar -zxpf base.tar.gz -C rootfs
	sudo cp -f /etc/resolv.conf rootfs/etc/resolv.conf
	sudo chroot rootfs /sbin/apk update
	sudo chroot rootfs /sbin/apk add \
		bash \
		bash-completion \
		alpine-sdk \
		coreutils \
		wget \
		curl \
		zip \
		unzip \
		git-lfs \
		subversion \
		cdrkit
	sudo chroot rootfs /sbin/apk add \
		gcc \
		ghc \
		gmp \
		libffi \
		musl-dev \
		sed \
		linux-headers \
		zlib-dev \
		jpeg-dev
	sudo chroot rootfs /sbin/apk add \
		python \
		py-pip \
		python-dev
	sudo chroot rootfs /sbin/apk add \
		graphviz \
		openjdk8 \
		ghostscript \
		ttf-dejavu
	sudo chroot rootfs /sbin/apk add \
		texlive-full > /dev/null
	sudo chroot rootfs \
		/usr/bin/$(DLR) $(DLR_FLAGS) $(PLANTUML_URL) \
		-o /usr/local/plantuml.jar
	sudo -H chroot rootfs /usr/bin/python -m pip install --upgrade \
		pip \
		setuptools \
		wheel 
	sudo -H chroot rootfs /usr/bin/python -m pip install --upgrade \
		colorama \
		netaddr \
		gitpython \
		plantuml \
		reportlab \
		tablib \
		ciscoconfparse \
		pyyaml \
		yml2json \
		xlsxwriter \
		xlsxcompare
	sudo -H chroot rootfs /usr/bin/python -m pip install --upgrade \
		nety
	sudo -H chroot rootfs /usr/bin/python -m pip install --upgrade \
		sphinx \
		sphinx-autobuild \
		sphinx-jinja \
		sphinx-git \
		sphinx_rtd_theme
	sudo -H chroot rootfs /usr/bin/python -m pip install --upgrade \
		sphinxcontrib-plantuml \
		sphinxcontrib-jupyter \
		sphinxcontrib_ansibleautodoc \
		sphinxcontrib-jsonschema \
		sphinxcontrib-confluencebuilder \
		sphinx-markdown-builder \
		sphinxcontrib-fulltoc
	sudo chroot rootfs \
		/usr/bin/$(DLR) $(DLR_FLAGS) $(ACROTEX_URL) \
		-o /tmp/acrotex.zip
	sudo chroot rootfs /usr/bin/unzip \
		/tmp/acrotex.zip -d /usr/share/texmf-dist/tex/latex/
	sudo chroot rootfs /usr/bin/mktexlsr
	sudo chroot rootfs /bin/rm -f \
		/tmp/acrotex.zip
	sudo chroot rootfs /bin/ln -s \
		/usr/share/fonts/ttf-dejavu \
		/usr/share/fonts/dejavu
	sudo chroot rootfs /sbin/apk add \
		ruby \
		ruby-dev
	sudo -H chroot rootfs /usr/bin/gem install \
		travis --no-rdoc --no-ri
	echo "# This file was automatically generated by WSL. To stop automatic generation of this file, remove this line." | sudo tee rootfs/etc/resolv.conf
	sudo rm -rf `sudo find rootfs/var/cache/apk/ -type f`
	sudo chmod +x rootfs

base.tar.gz:
	@echo -e '\e[1;31mDownloading base.tar.gz...\e[m'
	$(DLR) $(DLR_FLAGS) $(BASE_URL) -o base.tar.gz

clean:
	@echo -e '\e[1;31mCleaning files...\e[m'
	-rm ${OUT_ZIP}
	-rm -r ziproot
	-rm Launcher.exe
	-rm icons.zip
	-rm rootfs.tar.gz
	-sudo rm -r rootfs
	-rm base.tar.gz
	-rm install.ps1
	-rm addWSLfeature.ps1
	-rm wslgit.exe
