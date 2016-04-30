mkbootimg_tools
===============

HOW TO USE:
-----------

### Unpack boot/recovery(.img) support dtb(dt.img):
		./mkboot name.img namefolderout

	EXAMPLE
		./mkboot recoveryksuamg5.img ksuamg
		Unpack & decompress recoveryksuamg5.img to ksuamg
		  kernel         : /home/xiaolu/work/initramfs/s4/e330s/ksuamg5/zImage
		  ramdisk        : /home/xiaolu/work/initramfs/s4/e330s/ksuamg5/ramdisk.gz
		  page_size      : 2048
		  base_addr      : 0x00000000
		  kernel size    : 6911360
		  kernel_addr    : 0x00008000
		  ramdisk_size   : 2685222
		  ramdisk_addr   : 0x02000000
		  second_size    : 0
		  second_addr    : 0x00f00000
		  dtb_size       : 1427456
		  tags_addr      : 0x01e00000
		  cmdline        : console=null androidboot.hardware=qcom user_debug=31 maxcpus=2 msm_rtb.filter=0x3F
		Unpack completed.

### Repack boot/recovery(.img) support dtb(dt.img):
		./mkboot namefolderout newimgname.img

	EXAMPLE
		./mkboot ksuamg5 recovery.img
		mkbootimg from ksuamg5/img_info.
		  kernel         : /home/xiaolu/work/initramfs/s4/e330s/ksuamg5/zImage
		  ramdisk        : /home/xiaolu/work/initramfs/s4/e330s/ksuamg5/new_ramdisk.gz
		  page_size      : 
		  base_addr      : 0x00000000
		  kernel size    : 6911360
		  kernel_addr    : 0x00008000
		  ramdisk_size   : 2685222
		  ramdisk_addr   : 0x02000000
		  second_size    : 
		  second_addr    : 
		  dtb_size       : 1427456
		  dtb_img        : dt.img
		  tags_addr      : 0x01e00000
		  cmdline        : console=null androidboot.hardware=qcom user_debug=31 maxcpus=2 msm_rtb.filter=0x3F
		Kernel size: 6911360, new ramdisk size: 3416778, recovery.img: 11759616.
		recovery.img has been created.
		...

### Create a dt.img:
		yourkernelsources/scripts/dtbTool -s 2048 -o arch/arm/boot/dt.img -p scripts/dtc/ arch/arm/boot/

	EXAMPLE
		SHV-E330S_JB_Opensource/Kernel$ scripts/dtbTool -s 2048 -o arch/arm/boot/dt.img -p scripts/dtc/ arch/arm/boot/
		DTB combiner:
		  Input directory: '/media/diskd/kernel/SHV-E330S_JB_Opensource/Kernel/arch/arm/boot/'
		  Output file: '/media/diskd/kernel/SHV-E330S_JB_Opensource/Kernel/arch/arm/boot/dt.img'
		Found file: msm8974-sec-ks01-r03.dtb ... chipset: 2114015745, platform: 3, rev: 0
		Found file: msm8974-sec-ks01-r07.dtb ... chipset: 2114015745, platform: 7, rev: 0
		Found file: msm8974-sec-ks01-r06.dtb ... chipset: 2114015745, platform: 6, rev: 0
		Found file: msm8974-sec-ks01-r04.dtb ... chipset: 2114015745, platform: 4, rev: 0
		Found file: msm8974-sec-ks01-r11.dtb ... chipset: 2114015745, platform: 11, rev: 0
		Found file: msm8974-sec-ks01-r02.dtb ... chipset: 2114015745, platform: 2, rev: 0
		Found file: msm8974-sec-ks01-r00.dtb ... chipset: 2114015745, platform: 0, rev: 0
		Found file: msm8974-sec-ks01-r05.dtb ... chipset: 2114015745, platform: 5, rev: 0
		Found file: msm8974-sec-ks01-r01.dtb ... chipset: 2114015745, platform: 1, rev: 0
		=> Found 9 unique DTB(s)

		Generating master DTB... completed


### dtbToolCM support dt-tag & dtb v2/3(https://github.com/CyanogenMod/android_device_qcom_common/tree/cm-13.0/dtbtool):

 	dtbToolCM -s 2048 -d "htc,project-id = <" -o arch/arm/boot/dt.img -p scripts/dtc/ arch/arm/boot/

