#!/system/bin/sh
# Copyright (c) 2012-2016, The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
#       copyright notice, this list of conditions and the following
#       disclaimer in the documentation and/or other materials provided
#       with the distribution.
#     * Neither the name of The Linux Foundation nor the names of its
#       contributors may be used to endorse or promote products derived
#      from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT
# ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
# IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#
PDS=`getprop ro.build.device.name`
echo "Lenovo" > /sys/class/android_usb/android0/iManufacturer
echo "$PDS" > /sys/class/android_usb/android0/iProduct

#chown -h root.system /sys/devices/platform/msm_hsusb/gadget/wakeup
#chmod -h 220 /sys/devices/platform/msm_hsusb/gadget/wakeup

# Set platform variables
if [ -f /sys/devices/soc0/hw_platform ]; then
    soc_hwplatform=`cat /sys/devices/soc0/hw_platform` 2> /dev/null
else
    soc_hwplatform=`cat /sys/devices/system/soc/soc0/hw_platform` 2> /dev/null
fi

# Get hardware revision
if [ -f /sys/devices/soc0/revision ]; then
    soc_revision=`cat /sys/devices/soc0/revision` 2> /dev/null
else
    soc_revision=`cat /sys/devices/system/soc/soc0/revision` 2> /dev/null
fi

#
# Allow persistent usb charging disabling
# User needs to set usb charging disabled in persist.usb.chgdisabled
#
target=`getprop ro.board.platform`
usbchgdisabled=`getprop persist.usb.chgdisabled`
case "$usbchgdisabled" in
    "") ;; #Do nothing here
    * )
    case $target in
        "msm8660")
        echo "$usbchgdisabled" > /sys/module/pmic8058_charger/parameters/disabled
        echo "$usbchgdisabled" > /sys/module/smb137b/parameters/disabled
	;;
        "msm8960")
        echo "$usbchgdisabled" > /sys/module/pm8921_charger/parameters/disabled
	;;
    esac
esac

usbcurrentlimit=`getprop persist.usb.currentlimit`
case "$usbcurrentlimit" in
    "") ;; #Do nothing here
    * )
    case $target in
        "msm8960")
        echo "$usbcurrentlimit" > /sys/module/pm8921_charger/parameters/usb_max_current
	;;
    esac
esac

#
# Check ESOC for external MDM
#
# Note: currently only a single MDM is supported
#
if [ -d /sys/bus/esoc/devices ]; then
for f in /sys/bus/esoc/devices/*; do
    if [ -d $f ]; then
        if [ `grep "^MDM" $f/esoc_name` ]; then
            esoc_link=`cat $f/esoc_link`
            break
        fi
    fi
done
fi

target=`getprop ro.board.platform`

# soc_ids for 8937
if [ -f /sys/devices/soc0/soc_id ]; then
	soc_id=`cat /sys/devices/soc0/soc_id`
else
	soc_id=`cat /sys/devices/system/soc/soc0/id`
fi

#
# Allow USB enumeration with default PID/VID
#
baseband=`getprop ro.baseband`
boot_mode=`getprop ro.bootmode`
usbmode=`getprop persist.sys.usb.mode`
case "$boot_mode" in
    "boot-factory" | "ffbm-00" | "ffbm-01" | "ffbm-02")
		case "$usbmode" in
			"" | "D3")
				#setprop persist.sys.usb.mode D1
				setprop persist.service.adb.secure 0
			;;
		esac
			#setprop persist.sys.usb.config diag,serial_smd,serial_tty,mass_storage,adb
                        setprop persist.sys.usb.config diag,serial_smd,serial_tty,adb
			#setprop persist.sys.usb.config diag,serial_smd,rmnet_ipa,adb
        ;;
	*)
		case "$usbmode" in
			"" | "D1")
				#setprop persist.sys.usb.config diag,serial_smd,serial_tty,mass_storage,adb
                                setprop persist.sys.usb.config diag,serial_smd,serial_tty,adb
			;;
			*)
				serialnum=`getprop ro.serialno`
					case "$serialnum" in
						"");; #Do nothing, use default serial number
						*)
							echo "$serialnum" > /sys/class/android_usb/android0/iSerial
						;;
					esac
			;;
		esac
	;;
esac

# echo 1  > /sys/class/android_usb/f_mass_storage/lun/nofua
usb_config=`getprop persist.sys.usb.config`
case "$usb_config" in
    "none" | "adb") #USB persist config not set, select default configuration
      case "$esoc_link" in
          "PCIe")
              setprop persist.sys.usb.config diag,diag_mdm,serial_cdev,rmnet_qti_ether,mass_storage,adb
          ;;
          *)
	  case "$baseband" in
	      "apq")
	          setprop persist.sys.usb.config diag,adb
	      ;;
	      *)
	      case "$soc_hwplatform" in
	          "Dragon" | "SBC")
	              setprop persist.sys.usb.config diag,adb
	          ;;
                  *)
	          case "$target" in
                      "msm8916")
		          setprop persist.sys.usb.config diag,serial_smd,rmnet_bam,adb
		      ;;
	              "msm8994" | "msm8992")
	                  setprop persist.sys.usb.config diag,serial_smd,serial_tty,rmnet_ipa,mass_storage,adb
		      ;;
	              "msm8996")
	                  setprop persist.sys.usb.config diag,serial_cdev,serial_tty,rmnet_ipa,mass_storage,adb
		      ;;
	              "msm8909")
		          setprop persist.sys.usb.config diag,serial_smd,rmnet_qti_bam,adb
		      ;;
	              "msm8937")
			    case "$soc_id" in
				    "313" | "320")
				       setprop persist.sys.usb.config diag,serial_smd,serial_tty,adb
				    ;;
				    *)
				       setprop persist.sys.usb.config diag,serial_smd,rmnet_qti_bam,adb
				    ;;
			    esac
		      ;;
	              "msm8952" | "msm8953")
		          setprop persist.sys.usb.config diag,serial_smd,rmnet_ipa,adb
		      ;;
	              "msmcobalt")
		          setprop persist.sys.usb.config diag,serial_cdev,rmnet_gsi,adb
		      ;;
	              *)
		          setprop persist.sys.usb.config diag,adb
		      ;;
                  esac
	          ;;
	      esac
	      ;;
	  esac
	  ;;
      esac
      ;;
  * ) ;; #USB persist config exists, do nothing
esac

# set USB controller's device node
case "$target" in
    "msm8996")
        setprop sys.usb.controller "6a00000.dwc3"
	;;
    "msmcobalt")
        setprop sys.usb.controller "a800000.dwc3"
	;;
    *)
	;;
esac

# check configfs is mounted or not
#if [ -d /config/usb_gadget ]; then
#	setprop sys.usb.configfs 1
#fi

#
# Do target specific things
#
case "$target" in
    "msm8974")
# Select USB BAM - 2.0 or 3.0
        echo ssusb > /sys/bus/platform/devices/usb_bam/enable
    ;;
    "apq8084")
	if [ "$baseband" == "apq" ]; then
		echo "msm_hsic_host" > /sys/bus/platform/drivers/xhci_msm_hsic/unbind
	fi
    ;;
    "msm8226")
         if [ -e /sys/bus/platform/drivers/msm_hsic_host ]; then
             if [ ! -L /sys/bus/usb/devices/1-1 ]; then
                 echo msm_hsic_host > /sys/bus/platform/drivers/msm_hsic_host/unbind
             fi
         fi
    ;;
    "msm8994" | "msm8992" | "msm8996" | "msm8953")
        echo BAM2BAM_IPA > /sys/class/android_usb/android0/f_rndis_qc/rndis_transports
        echo 131072 > /sys/module/g_android/parameters/mtp_tx_req_len
        echo 131072 > /sys/module/g_android/parameters/mtp_rx_req_len
    ;;
    "msm8937")
	case "$soc_id" in
		"313" | "320")
		   echo BAM2BAM_IPA > /sys/class/android_usb/android0/f_rndis_qc/rndis_transports
		;;
	esac
   ;;
esac

#
# set module params for embedded rmnet devices
#
rmnetmux=`getprop persist.rmnet.mux`
case "$baseband" in
    "mdm" | "dsda" | "sglte2")
        case "$rmnetmux" in
            "enabled")
                    echo 1 > /sys/module/rmnet_usb/parameters/mux_enabled
                    echo 8 > /sys/module/rmnet_usb/parameters/no_fwd_rmnet_links
                    echo 17 > /sys/module/rmnet_usb/parameters/no_rmnet_insts_per_dev
            ;;
        esac
        echo 1 > /sys/module/rmnet_usb/parameters/rmnet_data_init
        # Allow QMUX daemon to assign port open wait time
        chown -h radio.radio /sys/devices/virtual/hsicctl/hsicctl0/modem_wait
    ;;
    "dsda2")
          echo 2 > /sys/module/rmnet_usb/parameters/no_rmnet_devs
          echo hsicctl,hsusbctl > /sys/module/rmnet_usb/parameters/rmnet_dev_names
          case "$rmnetmux" in
               "enabled") #mux is neabled on both mdms
                      echo 3 > /sys/module/rmnet_usb/parameters/mux_enabled
                      echo 8 > /sys/module/rmnet_usb/parameters/no_fwd_rmnet_links
                      echo 17 > write /sys/module/rmnet_usb/parameters/no_rmnet_insts_per_dev
               ;;
               "enabled_hsic") #mux is enabled on hsic mdm
                      echo 1 > /sys/module/rmnet_usb/parameters/mux_enabled
                      echo 8 > /sys/module/rmnet_usb/parameters/no_fwd_rmnet_links
                      echo 17 > /sys/module/rmnet_usb/parameters/no_rmnet_insts_per_dev
               ;;
               "enabled_hsusb") #mux is enabled on hsusb mdm
                      echo 2 > /sys/module/rmnet_usb/parameters/mux_enabled
                      echo 8 > /sys/module/rmnet_usb/parameters/no_fwd_rmnet_links
                      echo 17 > /sys/module/rmnet_usb/parameters/no_rmnet_insts_per_dev
               ;;
          esac
          echo 1 > /sys/module/rmnet_usb/parameters/rmnet_data_init
          # Allow QMUX daemon to assign port open wait time
          chown -h radio.radio /sys/devices/virtual/hsicctl/hsicctl0/modem_wait
    ;;
esac

#
# Add support for exposing lun0 as cdrom in mass-storage
#
cdromname="/system/etc/cdrom_install.iso"
platformver=`cat /sys/devices/soc0/hw_platform`
case "$target" in
	"msm8226" | "msm8610" | "msm8916")
		case $platformver in
			"QRD")
				echo "mounting usbcdrom lun"
				echo $cdromname > /sys/class/android_usb/android0/f_mass_storage/rom/file
				chmod 0444 /sys/class/android_usb/android0/f_mass_storage/rom/file
				;;
		esac
		;;
esac

#
# Initialize RNDIS Diag option. If unset, set it to 'none'.
#
diag_extra=`getprop persist.sys.usb.config.extra`
if [ "$diag_extra" == "" ]; then
	setprop persist.sys.usb.config.extra none
fi

# soc_ids for 8937
if [ -f /sys/devices/soc0/soc_id ]; then
	soc_id=`cat /sys/devices/soc0/soc_id`
else
	soc_id=`cat /sys/devices/system/soc/soc0/id`
fi

# enable rps cpus on msm8937 target
setprop sys.usb.rps_mask 0
case "$soc_id" in
	"294" | "295")
		setprop sys.usb.rps_mask 40
	;;
esac
