#!/system/bin/sh
# Copyright (c) 2012-2013, The Linux Foundation. All rights reserved.
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

# Set platform variables
target=`getprop ro.board.platform`
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


# Dynamic Memory Managment (DMM) provides a sys file system to the userspace
# that can be used to plug in/out memory that has been configured as unstable.
# This unstable memory can be in Active or In-Active State.
# Each of which the userspace can request by writing to a sys file.
#
# ro.dev.dmm = 1; Indicates that DMM is enabled in the Android User Space. This
# property is set in the Android system properties file.
#
# If ro.dev.dmm.dpd.start_address is set here then the target has a memory
# configuration that supports DynamicMemoryManagement.
init_DMM()
{
    block=-1

    case "$target" in
    "msm7630_surf" | "msm7630_1x" | "msm7630_fusion" | "msm8960")
        ;;
    *)
        return
        ;;
    esac

    mem="/sys/devices/system/memory"
    op=`cat $mem/movable_start_bytes`
    case "$op" in
    "0")
        log -p i -t DMM DMM Disabled. movable_start_bytes not set: $op
        ;;

    "$mem/movable_start_bytes: No such file or directory ")
        log -p i -t DMM DMM Disabled. movable_start_bytes does not exist: $op
        ;;

    *)
        log -p i -t DMM DMM available. movable_start_bytes at $op
        movable_start_bytes=0x`cat $mem/movable_start_bytes`
        block_size_bytes=0x`cat $mem/block_size_bytes`
        block=$((#${movable_start_bytes}/${block_size_bytes}))

        chown -h system.system $mem/memory$block/state
        chown -h system.system $mem/probe
        chown -h system.system $mem/active
        chown -h system.system $mem/remove

        case "$target" in
        "msm7630_surf" | "msm7630_1x" | "msm7630_fusion")
            echo $movable_start_bytes > $mem/probe
            case "$?" in
            "0")
                log -p i -t DMM $movable_start_bytes to physical hotplug succeeded.
                ;;
            *)
                log -p e -t DMM $movable_start_bytes to physical hotplug failed.
                return
                ;;
            esac

            echo online > $mem/memory$block/state
            case "$?" in
            "0")
                log -p i -t DMM \'echo online\' to logical hotplug succeeded.
                ;;
            *)
                log -p e -t DMM \'echo online\' to logical hotplug failed.
                return
                ;;
            esac
            ;;
        esac

        setprop ro.dev.dmm.dpd.start_address $movable_start_bytes
        setprop ro.dev.dmm.dpd.block $block
        ;;
    esac

    case "$target" in
    "msm8960")
        return
        ;;
    esac

    # For 7X30 targets:
    # ro.dev.dmm.dpd.start_address is set when the target has a 2x256Mb memory
    # configuration. This is also used to indicate that the target is capable of
    # setting EBI-1 to Deep Power Down or Self Refresh.
    op=`cat $mem/low_power_memory_start_bytes`
    case "$op" in
    "0")
        log -p i -t DMM Self-Refresh-Only Disabled. low_power_memory_start_bytes not set:$op
        ;;
    "$mem/low_power_memory_start_bytes No such file or directory ")
        log -p i -t DMM Self-Refresh-Only Disabled. low_power_memory_start_bytes does not exist:$op
        ;;
    *)
        log -p i -t DMM Self-Refresh-Only available. low_power_memory_start_bytes at $op
        ;;
    esac
}

#
# For controlling console and shell on console on 8960 - perist.serial.enable 8960
# On other target use default ro.debuggable property.
#
serial=`getprop persist.serial.enable`
dserial=`getprop ro.debuggable`
case "$target" in
    "msm8960")
        case "$serial" in
            "0")
                echo 0 > /sys/devices/platform/msm_serial_hsl.0/console
                ;;
            "1")
                echo 1 > /sys/devices/platform/msm_serial_hsl.0/console
                start console
                ;;
            *)
                case "$dserial" in
                     "1")
                         start console
                         ;;
                esac
                ;;
        esac
        ;;

    "msm8610" | "msm8974" | "msm8226")
	case "$serial" in
	     "0")
		echo 0 > /sys/devices/f991f000.serial/console
		;;
	     "1")
		echo 1 > /sys/devices/f991f000.serial/console
		start console
		;;
            *)
		case "$dserial" in
                     "1")
			start console
			;;
		esac
		;;
	esac
	;;
    *)
        case "$dserial" in
            "1")
                start console
                ;;
        esac
        ;;
esac

case "$target" in
    "msm7630_surf" | "msm7630_1x" | "msm7630_fusion")
        insmod /system/lib/modules/ss_mfcinit.ko
        insmod /system/lib/modules/ss_vencoder.ko
        insmod /system/lib/modules/ss_vdecoder.ko
        chmod -h 0666 /dev/ss_mfc_reg
        chmod -h 0666 /dev/ss_vdec
        chmod -h 0666 /dev/ss_venc

        init_DMM
        ;;

    "msm8960")
        init_DMM
        ;;
esac
