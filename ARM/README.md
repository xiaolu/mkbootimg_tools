Original Source Modified By:
Modding.MyMind XDA \
ModdingMyMind AF

Built to be used on Arm devices.

Move the bash binary to /system/xbin.
The rest must remain in the project folder.

### Unpack Boot.img or Recovery.img:
	root@android:/data/local/tmp/mkbootimg_tool/ARM # ./mkboot recovery_stock.img recoveryfolder

	Unpack & decompress recovery_stock.img to recoveryfolder

	****** WARNING ******* WARNING ******* WARNING ******                   

	This image is built using NON-standard mkbootimg!                       
	BASE is 0x001fff00
	KERNEL_OFFSET is 0x00408100
	RAMDISK_OFFSET is 0x00100100
	SECOND_OFFSET is 0x00d00100

	You can modify mkbootimg.c with the above value(s)                      

	****** WARNING ******* WARNING ******* WARNING ******                   

	  kernel         : zImage
	  ramdisk        : ramdisk
	  page size      : 2048
	  kernel size    : 6597520
	  ramdisk size   : 3141533
	  base           : 0x001fff00
	  kernel offset  : 0x00408100
	  ramdisk offset : 0x00100100
	  second_offset  : 0x00d00100
	  tags offset    : 0x00000100
	  cmd line       : vmalloc=384M mem=2044m@0x200000 psci=enable mmcparts=mmcblk0:p1(vrl),p2(vrl_backup),p7(modemnvm_factory),p18(splash),p22(dfx),p23(modemnvm_backup),p24(modemnvm_img),p25(modemnvm_system),p26(modem),p27(modem_dsp),p28(modem_om),p29(modemnvm_update),p30(3rdmodem),p31(3rdmodemnvm),p32(3rdmodemnvmbkp)

	ramdisk is gzip format.
	Unpack completed.

	root@android:/data/local/tmp/mkbootimg_tools-master/ARM #

### Repack Boot.img or Recovery.img:
	root@android:/data/local/tmp/mkbootimg_tools-master # ./mkboot recoveryfolder recovery_stock.img
	mkbootimg from recoveryfolder/img_info.
	  kernel         : zImage
	  ramdisk        : new_ramdisk.gz
	  page size      : 2048
	  kernel size    : 6597520
	  ramdisk size   : 3142833
	  base           : 0x001fff00
	  kernel offset  : 0x00408100
	  ramdisk offset : 0x00100100
	  tags offset    : 0x00000100
	  cmd line       : vmalloc=384M mem=2044m@0x200000 psci=enable mmcparts=mmcblk0:p1(vrl),p2(vrl_backup),p7(modemnvm_factory),p18(splash),p22(dfx),p23(modemnvm_backup),p24(modemnvm_img),p25(modemnvm_system),p26(modem),p27(modem_dsp),p28(modem_om),p29(modemnvm_update),p30(3rdmodem),p31(3rdmodemnvm),p32(3rdmodemnvmbkp)
	Kernel size: 6597520, new ramdisk size: 3142833, recovery_stock.img: 9744384.
	recovery_stock.img has been created.
	...
	root@android:/data/local/tmp/mkbootimg_tools-master #