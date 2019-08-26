#!/system/bin/sh
# Copyright (c) 2012, The Linux Foundation. All rights reserved.
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

target="$1"
serial="$2"

# No path is set up at this point so we have to do it here.
PATH=/sbin:/system/sbin:/system/bin:/system/xbin
export PATH

mount_needed=false;

if [ ! -f /system/etc/boot_fixup ];then
# This should be the first command
# remount system as read-write.
  mount -o rw,remount,barrier=1 /system
  mount_needed=true;
fi

# **** WARNING *****
# This runs in a single-threaded, critical path portion
# of the Android bootup sequence.  This is to guarantee
# all necessary system partition fixups are done before
# the rest of the system starts up.  Run any non-
# timing critical tasks in a separate process to
# prevent slowdown at boot.

# Run modem link script
if [ -f /system/etc/init.qcom.modem_links.sh ]; then
  /system/bin/sh /system/etc/init.qcom.modem_links.sh
fi

# Run mdm link script
if [ -f /system/etc/init.qcom.mdm_links.sh ]; then
  /system/bin/sh /system/etc/init.qcom.mdm_links.sh
fi

# Run wifi script
if [ -f /system/etc/init.qcom.wifi.sh ]; then
  /system/bin/sh /system/etc/init.qcom.wifi.sh "$target" "$serial"
fi

# Run the sensor script
if [ -f /system/etc/init.qcom.sensor.sh ]; then
  /system/bin/sh /system/etc/init.qcom.sensor.sh
fi

touch /system/etc/boot_fixup

if $mount_needed ;then
# This should be the last command
# remount system as read-only.
  mount -o ro,remount,barrier=1 /system
fi
