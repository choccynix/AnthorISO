subarch: amd64
version_stamp: @VERSION@
target: livecd-stage1
rel_type: anthoros
profile: default/linux/amd64/23.0/musl/llvm
snapshot_treeish: @TREEISH@
source_subpath: anthoros/stage3-amd64-musl-llvm-openrc-@VERSION@
compression_mode: pixz

portage_confdir: @REPO_DIR@/catalyst/portage

livecd/use:
	unicode
	livecd

livecd/packages:
	app-editors/nano
	app-editors/vim
	app-misc/screen
	app-misc/livecd-tools
	app-shells/bash
	sys-fs/e2fsprogs
	sys-fs/dosfstools
	sys-fs/btrfs-progs
	sys-fs/xfsprogs
	sys-block/parted
	net-misc/openssh
	net-misc/dhcpcd
	net-misc/curl
	net-misc/wget
	sys-apps/iproute2
	net-wireless/wpa_supplicant
	net-wireless/iw
	sys-apps/pciutils
	sys-apps/usbutils
	sys-apps/gptfdisk
	sys-process/htop
	sys-kernel/linux-firmware
