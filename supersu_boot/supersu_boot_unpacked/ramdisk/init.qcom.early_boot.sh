#!/system/bin/sh
# Copyright (c) 2012-2013,2016 The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of The Linux Foundation nor
#       the names of its contributors may be used to endorse or promote
#       products derived from this software without specific prior written
#       permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NON-INFRINGEMENT ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

export PATH=/system/bin

# Set platform variables
if [ -f /sys/devices/soc0/hw_platform ]; then
    soc_hwplatform=`cat /sys/devices/soc0/hw_platform` 2> /dev/null
else
    soc_hwplatform=`cat /sys/devices/system/soc/soc0/hw_platform` 2> /dev/null
fi
if [ -f /sys/devices/soc0/soc_id ]; then
    soc_hwid=`cat /sys/devices/soc0/soc_id` 2> /dev/null
else
    soc_hwid=`cat /sys/devices/system/soc/soc0/id` 2> /dev/null
fi
if [ -f /sys/devices/soc0/platform_version ]; then
    soc_hwver=`cat /sys/devices/soc0/platform_version` 2> /dev/null
else
    soc_hwver=`cat /sys/devices/system/soc/soc0/platform_version` 2> /dev/null
fi

if [ -f /sys/class/graphics/fb0/virtual_size ]; then
    res=`cat /sys/class/graphics/fb0/virtual_size` 2> /dev/null
    fb_width=${res%,*}
fi

log -t BOOT -p i "MSM target '$1', SoC '$soc_hwplatform', HwID '$soc_hwid', SoC ver '$soc_hwver'"

function set_density_by_fb() {
    #put default density based on width
    if [ -z $fb_width ]; then
        setprop ro.sf.lcd_density 320
    else
        if [ $fb_width -ge 1080 ]; then
           setprop ro.sf.lcd_density 320
        elif [ $fb_width -ge 800 ]; then
           setprop ro.sf.lcd_density 213 #for 800X1280 resolution
        elif [ $fb_width -ge 720 ]; then
           setprop ro.sf.lcd_density 320 #for 720X1280 resolution
        elif [ $fb_width -ge 480 ]; then
            setprop ro.sf.lcd_density 240 #for 480X854 QRD resolution
        else
            setprop ro.sf.lcd_density 160
        fi
    fi
}
target=`getprop ro.board.platform`
case "$target" in
    "msm7630_surf" | "msm7630_1x" | "msm7630_fusion")
        case "$soc_hwplatform" in
            "FFA" | "SVLTE_FFA")
                # linking to surf_keypad_qwerty.kcm.bin instead of surf_keypad_numeric.kcm.bin so that
                # the UI keyboard works fine.
                ln -s  /system/usr/keychars/surf_keypad_qwerty.kcm.bin /system/usr/keychars/surf_keypad.kcm.bin
                ;;
            "Fluid")
                setprop ro.sf.lcd_density 240
                setprop qcom.bt.dev_power_class 2
                ;;
            *)
                ln -s  /system/usr/keychars/surf_keypad_qwerty.kcm.bin /system/usr/keychars/surf_keypad.kcm.bin
                ;;
        esac
        ;;

    "msm8660")
        case "$soc_hwplatform" in
            "Fluid")
                setprop ro.sf.lcd_density 240
                ;;
            "Dragon")
                setprop ro.sound.alsa "WM8903"
                ;;
        esac
        ;;

    "msm8960")
        # lcd density is write-once. Hence the separate switch case
        case "$soc_hwplatform" in
            "Liquid")
                if [ "$soc_hwver" == "196608" ]; then # version 0x30000 is 3D sku
                    setprop ro.sf.hwrotation 90
                fi

                setprop ro.sf.lcd_density 160
                ;;
            "MTP")
                setprop ro.sf.lcd_density 240
                ;;
            *)
                case "$soc_hwid" in
                    "109")
                        setprop ro.sf.lcd_density 160
                        ;;
                    *)
                        setprop ro.sf.lcd_density 240
                        ;;
                esac
            ;;
        esac

        #Set up composition type based on the target
        case "$soc_hwid" in
            87)
                #8960
                setprop debug.composition.type dyn
                ;;
            153|154|155|156|157|138)
                #8064 V2 PRIME | 8930AB | 8630AB | 8230AB | 8030AB | 8960AB
                setprop debug.composition.type c2d
                ;;
            *)
        esac
        ;;

    "msm8974")
        case "$soc_hwplatform" in
            "Liquid")
                setprop ro.sf.lcd_density 160
                # Liquid do not have hardware navigation keys, so enable
                # Android sw navigation bar
                setprop ro.hw.nav_keys 0
                ;;
            "Dragon")
                setprop ro.sf.lcd_density 240
                ;;
            *)
                setprop ro.sf.lcd_density 320
                ;;
        esac
        ;;

    "msm8226")
        case "$soc_hwplatform" in
            *)
                setprop ro.sf.lcd_density 320
                ;;
        esac
        ;;

    "msm8610" | "apq8084" | "mpq8092")
        case "$soc_hwplatform" in
            *)
                setprop ro.sf.lcd_density 240
                ;;
        esac
        ;;
    "apq8084")
        case "$soc_hwplatform" in
            "Liquid")
                setprop ro.sf.lcd_density 320
                # Liquid do not have hardware navigation keys, so enable
                # Android sw navigation bar
                setprop ro.hw.nav_keys 0
                ;;
            "SBC")
                setprop ro.sf.lcd_density 200
                # SBC do not have hardware navigation keys, so enable
                # Android sw navigation bar
                setprop qemu.hw.mainkeys 0
                ;;
            *)
                setprop ro.sf.lcd_density 480
                ;;
        esac
        ;;
    "msm8996")
        case "$soc_hwplatform" in
            "Dragon")
                setprop ro.sf.lcd_density 240
                setprop qemu.hw.mainkeys 0
                ;;
            "SBC")
                setprop ro.sf.lcd_density 240
                setprop qemu.hw.mainkeys 0
                ;;
            *)
                setprop ro.sf.lcd_density 560
                ;;
        esac
        ;;
    "msm8937" | "msm8940")
        # Set ro.opengles.version based on chip id.
        # MSM8937 and MSM8940  variants supports OpenGLES 3.1
        # 196608 is decimal for 0x30000 to report version 3.0
        # 196609 is decimal for 0x30001 to report version 3.1
        # 196610 is decimal for 0x30002 to report version 3.2
        case "$soc_hwid" in
            294|295|296|297|298|313)
                setprop ro.opengles.version 196610
                ;;
            303|307|308|309|320)
                # Vulkan is not supported for 8917 & 8920 variants
                setprop ro.opengles.version 196608
                setprop persist.graphics.vulkan.disable true
                ;;
            *)
                setprop ro.opengles.version 196608
                ;;
        esac
        ;;
    "msm8998")
        case "$soc_hwplatform" in
            *)
                setprop ro.sf.lcd_density 560
                if [ ! -e /dev/kgsl-3d0 ]; then
                    setprop persist.sys.force_sw_gles 1
                    setprop sdm.idle_time 0
                else
                    setprop persist.sys.force_sw_gles 0
                fi
                ;;
        esac
        ;;
    "msm8953")
        cap_ver=`cat /sys/devices/soc/1d00000.qcom,vidc/capability_version` 2> /dev/null
        if [ $cap_ver -eq 1 ]; then
            setprop media.msm8953.version 1
            setprop media.settings.xml /etc/media_profiles_8953_v1.xml
        fi
        ;;
esac
#set default lcd density
#Since lcd density has read only
#property, it will not overwrite previous set
#property if any target is setting forcefully.
set_density_by_fb

# Setup display nodes & permissions
# HDMI can be fb1 or fb2
# Loop through the sysfs nodes and determine
# the HDMI(dtv panel)

function set_perms() {
    #Usage set_perms <filename> <ownership> <permission>
    chown -h $2 $1
    chmod $3 $1
}

function setHDMIPermission() {
   file=/sys/class/graphics/fb$1
   dev_file=/dev/graphics/fb$1
   dev_gfx_hdmi=/devices/virtual/switch/hdmi

   set_perms $file/hpd system.graphics 0664
   set_perms $file/res_info system.graphics 0664
   set_perms $file/vendor_name system.graphics 0664
   set_perms $file/product_description system.graphics 0664
   set_perms $file/video_mode system.graphics 0664
   set_perms $file/format_3d system.graphics 0664
   set_perms $file/s3d_mode system.graphics 0664
   set_perms $file/dynamic_fps system.graphics 0664
   set_perms $file/msm_fb_dfps_mode system.graphics 0664
   set_perms $file/cec/enable system.graphics 0664
   set_perms $file/cec/logical_addr system.graphics 0664
   set_perms $file/cec/rd_msg system.graphics 0664
   set_perms $file/pa system.graphics 0664
   set_perms $file/cec/wr_msg system.graphics 0600
   set_perms $file/hdcp/tp system.graphics 0664
   set_perms $file/hdmi_audio_cb audioserver.audio 0600
   ln -s $dev_file $dev_gfx_hdmi
}

# check for HDMI connection
for fb_cnt in 0 1 2 3
do
    file=/sys/class/graphics/fb$fb_cnt/msm_fb_panel_info
    if [ -f "$file" ]
    then
      cat $file | while read line; do
        case "$line" in
            *"is_pluggable"*)
             case "$line" in
                  *"1"*)
                  setHDMIPermission $fb_cnt
             esac
        esac
      done
    fi
done



# check for mdp caps
setprop debug.gralloc.gfx_ubwc_disable 1
file=/sys/class/graphics/fb0/mdp/caps
if [ -f "$file" ]
then
    cat $file | while read line; do
      case "$line" in
                *"ubwc"*)
                setprop debug.gralloc.enable_fb_ubwc 1
                setprop debug.gralloc.gfx_ubwc_disable 0
            esac
    done
fi

file=/sys/class/graphics/fb0
if [ -d "$file" ]
then
        set_perms $file/idle_time system.graphics 0664
        set_perms $file/dynamic_fps system.graphics 0664
        set_perms $file/dyn_pu system.graphics 0664
        set_perms $file/modes system.graphics 0664
        set_perms $file/mode system.graphics 0664
        set_perms $file/msm_cmd_autorefresh_en system.graphics 0664
fi

# set lineptr permissions for all displays
for fb_cnt in 0 1 2 3
do
    file=/sys/class/graphics/fb$fb_cnt/lineptr_value
    if [ -f "$file" ]; then
        set_perms $file system.graphics 0664
    fi
done

boot_reason=`cat /proc/sys/kernel/boot_reason`
reboot_reason=`getprop ro.boot.alarmboot`
power_off_alarm_file=`cat /persist/alarm/powerOffAlarmSet`
if [ "$boot_reason" = "3" ] || [ "$reboot_reason" = "true" ]; then
    if [ "$power_off_alarm_file" = "1" ]
    then
        setprop ro.alarm_boot true
        setprop debug.sf.nobootanimation 1
    fi
else
    setprop ro.alarm_boot false
fi

# copy GPU frequencies to system property
if [ -f /sys/class/kgsl/kgsl-3d0/gpu_available_frequencies ]; then
    gpu_freq=`cat /sys/class/kgsl/kgsl-3d0/gpu_available_frequencies` 2> /dev/null
    setprop ro.gpu.available_frequencies "$gpu_freq"
fi
