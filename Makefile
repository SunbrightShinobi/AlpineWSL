OUT_ZIP=Alpine.zip
LNCR_EXE=Alpine.exe

DLR=curl
DLR_FLAGS=-L
BASE_URL=http://dl-cdn.alpinelinux.org/alpine/v3.8/releases/x86_64/alpine-minirootfs-3.8.0-x86_64.tar.gz
GLIBC_URL=https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.28-r0/glibc-2.28-r0.apk
LNCR_ZIP_URL=https://github.com/yuk7/wsldl/releases/download/18080900/icons.zip
LNCR_ZIP_EXE=Alpine.exe
PLANTUML_URL=http://sourceforge.net/projects/plantuml/files/plantuml.jar/download
ACROTEX_URL=http://mirrors.ctan.org/macros/latex/contrib/acrotex.zip
INSTALL_PS_SCRIPT=https://github.com/binarylandscapes/AlpineWSL/blob/master/wslDistroInstall_alpineLinux.ps1
FEATURE_PS_SCRIPT=https://github.com/binarylandscapes/AlpineWSL/blob/master/wslFeatureInstall.ps1
USER_PS_SCRIPT=https://github.com/binarylandscapes/AlpineWSL/blob/master/wslUserSetup_alpineLinux.ps1
wslGit=https://github.com/andy-5/wslgit/releases/download/v0.6.0/wslgit.exe
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
	cp setupUser.ps1 ziproot/
	cp wslgit.exe ziproot/

ps_scripts:
	$(DLR) $(DLR_FLAGS) $(INSTALL_PS_SCRIPT) -o install.ps1
	$(DLR) $(DLR_FLAGS) $(FEATURE_PS_SCRIPT) -o addWSLfeature.ps1
	$(DLR) $(DLR_FLAGS) $(USER_PS_SCRIPT) -o setupUser.ps1

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

rootfs: base.tar.gz glibc.apk
	@echo -e '\e[1;31mBuilding rootfs...\e[m'
	mkdir rootfs
	sudo tar -zxpf base.tar.gz -C rootfs
	sudo cp -f /etc/resolv.conf rootfs/etc/resolv.conf
	sudo cp -f glibc.apk rootfs/
	sudo chroot rootfs /sbin/apk add /glibc.apk --allow-untrusted
	sudo rm -rf rootfs/glibc.apk
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
		python3 \
		py3-pip \
		python3-dev \
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
		wheel
	sudo -H chroot rootfs /usr/bin/python3 -m pip install --upgrade \
		pip \
		wheel
	sudo -H chroot rootfs /usr/bin/python3 -m pip install --upgrade \
		sphinx==1.7.5 \
		sphinx-autobuild \
		sphinx-jinja \
		netaddr \
		gitpython \
		seqdiag \
		sphinxcontrib-seqdiag \
		nwdiag \
		sphinxcontrib-nwdiag \
		blockdiag \
		sphinxcontrib-blockdiag \
		actdiag \
		sphinxcontrib-actdiag \
		sphinx-git \
		sphinx_rtd_theme \
		plantuml \
		reportlab \
		sphinxcontrib-plantuml \
		colorama
	sudo -H chroot rootfs /usr/bin/python3 -m pip install --upgrade \
		tablib \
		ciscoconfparse \
		nety \
		sphinxcontrib-jupyter \
		sphinxcontrib_ansibleautodoc \
		sphinxcontrib-jsonschema \
		sphinxcontrib-confluencebuilder \
		pyyaml==3.11 \
		yml2json
	sudo chroot rootfs \
		/usr/bin/$(DLR) $(DLR_FLAGS) $(ACROTEX_URL) \
		-o /tmp/acrotex.zip
	sudo chroot rootfs /usr/bin/unzip \
		/tmp/acrotex.zip -d /usr/share/texmf-dist/tex/latex/
	#sudo chroot rootfs/usr/share/texmf-dist/tex/latex/acrotex \
	#	/usr/bin/latex acrotex.ins
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
		travis -v 1.8.9 --no-rdoc --no-ri
	echo "# This file was automatically generated by WSL. To stop automatic generation of this file, remove this line." | sudo tee rootfs/etc/resolv.conf
	sudo rm -rf `sudo find rootfs/var/cache/apk/ -type f`
	sudo chmod +x rootfs

base.tar.gz:
	@echo -e '\e[1;31mDownloading base.tar.gz...\e[m'
	$(DLR) $(DLR_FLAGS) $(BASE_URL) -o base.tar.gz

glibc.apk:
	@echo -e '\e[1;31mDownloading glibc.apk...\e[m'
	$(DLR) $(DLR_FLAGS) $(GLIBC_URL) -o glibc.apk

clean:
	@echo -e '\e[1;31mCleaning files...\e[m'
	-rm ${OUT_ZIP}
	-rm -r ziproot
	-rm Launcher.exe
	-rm icons.zip
	-rm rootfs.tar.gz
	-sudo rm -r rootfs
	-rm base.tar.gz
	-rm glibc.apk
	-rm install.ps1
	-rm addWSLfeature.ps1
	-rm setupUser.ps1
	-rm wslgit.exe
