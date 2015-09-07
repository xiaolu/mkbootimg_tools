1. Built to be used on Arm devices.

2. All binaries are statically compiled using the arm-linux-androideabi and arm-linux-gnueabi toolchains.

3. Run the mkboot script and have fun (mkboot script is a shebang manipulator)

NOTE: This project (ARM) is designed to work on Android (ARM) devices, however, it will also work on Linux as well. Tested and confirmed working on Ubuntu 15.04.

### Unpack Boot.img or Recovery.img:
	root@android:/data/local/tmp/mkbootimg_tool/ARM # ./mkboot boot.img bootfolder

	Unpack & decompress boot.img to bootfolder

	****** WARNING ******* WARNING ******* WARNING ******

	This image is built using NON-standard mkbootimg!

	BASE is 0x80400000
	RAMDISK_OFFSET is 0x01408000

	You can modify mkbootimg.c with the above value(s)

	****** WARNING ******* WARNING ******* WARNING ******

	  kernel         : zImage
	  ramdisk        : ramdisk
	  page size      : 2048
	  kernel size    : 5690888
	  ramdisk size   : 520206
	  base           : 0x80400000   (Non Standard)
	  kernel offset  : 0x00008000
	  ramdisk offset : 0x01408000   (Non Standard)
	  second offset  : 0x00f00000
	  tags offset    : 0x00000100
	  cmd line       : console=ttyHSL0,115200,n8 user_debug=31

	Ramdisk is gzip format.
	1851 blocks
	Unpack completed.

	root@android:/data/local/tmp/mkbootimg_tools-master/ARM #

### Repack Boot.img or Recovery.img:
	root@android:/data/local/tmp/mkbootimg_tools-master/ARM # ./mkboot bootfolder boot.img

	mkbootimg from bootfolder/img_info.

	  kernel         : zImage
	  ramdisk        : new_ramdisk.gzip
	  page size      : 2048
	  kernel size    : 5690888
	  ramdisk size   : 521739
	  base           : 0x80400000
	  kernel offset  : 0x00008000
	  ramdisk offset : 0x01408000
	  second offset  : 0x00f00000
	  tags offset    : 0x00000100
	  cmd line       : console=ttyHSL0,115200,n8 user_debug=31

	Kernel size: 5690888, new ramdisk size: 521739, boot.img: 6215680.

	boot.img has been created.
	
	root@android:/data/local/tmp/mkbootimg_tools-master/ARM #

### Repack Boot.img or Recovery.img with larger build than original:
	root@android:/data/local/tmp/mkbootimg_tools-master/ARM # ./mkboot bootfolder boot.img

	mkbootimg from bootfolder/img_info.

	  kernel         : zImage
	  ramdisk        : new_ramdisk.gzip
	  page size      : 2048
	  kernel size    : 5690888
	  ramdisk size   : 11233890
	  base           : 0x80400000
	  kernel offset  : 0x00008000
	  ramdisk offset : 0x01408000
	  second offset  : 0x00f00000
	  tags offset    : 0x00000100
	  cmd line       : console=ttyHSL0,115200,n8 user_debug=31

	Kernel size: 5690888, new ramdisk size: 11233890, boot.img: 16928768.

	boot.img has been created.


	****** CAUTION ******* CAUTION ******* CAUTION ******

	boot.img is 151552 bytes larger than
	the original build! Make sure this new
	size is not larger than the actual partition!

	****** CAUTION ******* CAUTION ******* CAUTION ******
	
	root@android:/data/local/tmp/mkbootimg_tools-master/ARM #
