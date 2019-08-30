#!/system/bin/sh

# Detects if we have a /data partition that is not actually using file encryption even though
# the device expects it. If so, try to patch the fstabs so we can actually boot.

KILLFBE=false
HARDWARE=$(getprop ro.boot.hardware)
if (! `mount 2>/dev/null | grep " /data " >/dev/null`); then
  DATA=$(cat /odm/etc/fstab.$HARDWARE /vendor/etc/fstab.$HARDWARE /fstab.$HARDWARE 2>/dev/null | grep -m 1 " /data " | tr -s " ")
  if (`echo "$DATA" 2>/dev/null | grep fileencryption >/dev/null`); then
    DEV=$(echo $DATA | cut -f 1 -d " ")
    echo $DEV
    if (`mount -t ext4 -o ro $DEV /data >/dev/null 2>/dev/null`); then
      if [ -f "/data/system/packages.xml" ]; then
        KILLFBE=true
      fi
      umount /data
    fi
  fi
fi

# remove_fbe infstab outfstab
remove_fbe() {
  umount $1
  if (`cat $1 2>/dev/null | grep fileencryption >/dev/null`); then
    cat $1 2>/dev/null | sed 's/,fileencryption=.*[, ]/,/' > $2
    for i in `ls -lZ $1 2>/dev/null`; do
      if (`echo $i | grep object_r >/dev/null`); then
        chcon $i $2
      fi
    done
    mount -o bind $2 $1
  fi
}

if ($KILLFBE); then
  mkdir /dev/block/supersu_fbe
  remove_fbe /odm/etc/fstab.$HARDWARE /dev/block/supersu_fbe/fstab.odm
  remove_fbe /vendor/etc/fstab.$HARDWARE /dev/block/supersu_fbe/fstab.vendor
  remove_fbe /fstab.$HARDWARE /dev/block/supersu_fbe/fstab.rootfs
fi
