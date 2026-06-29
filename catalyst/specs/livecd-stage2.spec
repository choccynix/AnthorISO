subarch: amd64
version_stamp: @VERSION@
target: livecd-stage2
rel_type: anthoros
profile: default/linux/amd64/23.0/musl/llvm
snapshot_treeish: @TREEISH@
source_subpath: anthoros/livecd-stage1-amd64-@VERSION@
compression_mode: pixz

portage_confdir: @REPO_DIR@/catalyst/portage

livecd/bootargs: dokeymap
livecd/fstype: squashfs
livecd/iso: anthoros-amd64-@VERSION@.iso
livecd/type: gentoo-release-minimal
livecd/volid: AnthorOS amd64 @VERSION@
livecd/depclean: yes

boot/kernel: anthoros
boot/kernel/anthoros/distkernel: yes
boot/kernel/anthoros/sources: gentoo-kernel-bin
boot/kernel/anthoros/packages:
	sys-boot/grub
	sys-kernel/dracut

boot/kernel/anthoros/dracut_args: --xz --no-hostonly -a dmsquash-live -o btrfs -o crypt -o i18n

livecd/rm:
	/usr/share/doc
	/usr/share/man
	/var/cache/distfiles
	/var/tmp/portage

livecd/empty:
	/var/cache/distfiles
	/var/tmp/portage
