mkbootimg_tools
===============

Unpack and repack boot.img,support dtb(qcdt dt.img).

xiaolu@xiaolu-ubuntu64:~/e330s$ mkboot recoveryksuamg5.img tmp
Unpack & decompress recoveryksuamg5.img to tmp
  kernel         : /home/xiaolu/work/initramfs/s4/e330s/tmp/zImage
  ramdisk        : /home/xiaolu/work/initramfs/s4/e330s/tmp/ramdisk.gz
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

xiaolu@xiaolu-ubuntu64:~/e330s$ mkboot recoveryksuamg5.img ksuamg5/ramdisk recovery.img
Repack recoveryksuamg5.img & ramdisk ksuamg5/ramdisk to recovery.img
  kernel         : /tmp/mkboot.WdWc/zImage
  ramdisk        : /tmp/mkboot.WdWc/ramdisk.gz
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
Kernel size: 6911360, new ramdisk size: 3426199, recovery.img: 11767808.
recovery.img has been created.
cleanup....

