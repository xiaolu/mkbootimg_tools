#!/system/bin/sh

MODE=$1

log_print() {
  echo "($MODE) $1"
  echo "($MODE) $1" >> /dev/.launch_daemonsu.log
  log -p i -t launch_daemonsu "($MODE) $1"
}

log_print "start"

if [ `mount | grep " /data " >/dev/null 2>&1; echo $?` -ne 0 ]; then
  # /data not mounted yet, we will be called again later
  log_print "abort: /data not mounted #1"
  exit
fi

if [ `mount | grep " /data " | grep "tmpfs" >/dev/null 2>&1; echo $?` -eq 0 ]; then
  # /data not mounted yet, we will be called again later
  log_print "abort: /data not mounted #2"
  exit
fi

if [ `cat /proc/mounts | grep /su >/dev/null 2>&1; echo $?` -eq 0 ]; then
  if [ -d "/su/bin" ]; then
    if [ `ps | grep -v "launch_daemonsu.sh" | grep "daemonsu" >/dev/null 2>&1; echo $?` -eq 0 ]; then
      # nothing to do here
      log_print "abort: daemonsu already running"
      exit
    fi
  fi
fi

setprop sukernel.daemonsu.launch $MODE

loopsetup() {
  LOOPDEVICE=
  for DEV in $(ls /dev/block/loop*); do
    if [ `losetup $DEV $1 >/dev/null 2>&1; echo $?` -eq 0 ]; then
      LOOPDEVICE=$DEV
      break
    fi
  done

  log_print "loopsetup($1): $LOOPDEVICE"
}

resize() {
  local LAST=
  local SIZE=
  for i in `ls -l /data/su.img`; do
    if [ "$LAST" = "root" ]; then
      if [ "$i" != "root" ]; then
        SIZE=$i
        break;
      fi
    fi
    LAST=$i
  done
  log_print "/data/su.img: $SIZE bytes"
  if [ "$SIZE" -lt "96000000" ]; then
    log_print "resizing /data/su.img to 96M"
    e2fsck -p -f /data/su.img
    resize2fs /data/su.img 96M
  fi
}

REBOOT=false

if [ ! -d "/su/bin" ]; then
  # not mounted yet, and doesn't exist already, merge
  log_print "/su not mounted yet"

  # copy boot image backups
  log_print "copying boot image backups from /cache to /data"
  cp -f /cache/stock_boot_* /data/. 2>/dev/null

  if [ -f "/data/su.img" ]; then
    log_print "/data/su.img found"
    e2fsck -p -f /data/su.img

    # make sure the image is the right size
    resize
  fi

  # newer image in /cache ?
  # only used if recovery couldn't mount /data
  if [ -f "/cache/su.img" ]; then
    log_print "/cache/su.img found"
    e2fsck -p -f /cache/su.img
    OVERWRITE=true

    if [ -f "/data/su.img" ]; then
      # attempt merge, this will fail pre-M
      # will probably also fail with /system installed busybox,
      # but then again, is there anything busybox doesn't break?
      # falls back to overwrite

      log_print "/data/su.img found"
      log_print "attempting merge"

      mkdir /cache/data_img
      mkdir /cache/cache_img

      # setup loop devices

      loopsetup /data/su.img
      LOOPDATA=$LOOPDEVICE
      log_print "$LOOPDATA /data/su.img"

      loopsetup /cache/su.img
      LOOPCACHE=$LOOPDEVICE
      log_print "$LOOPCACHE /cache/su.img"

      if [ ! -z "$LOOPDATA" ]; then
        if [ ! -z "$LOOPCACHE" ]; then
          # if loop devices have been setup, mount images
          OK=true

          if [ `mount -t ext4 -o rw,noatime $LOOPDATA /cache/data_img >/dev/null 2>&1; echo $?` -ne 0 ]; then
            OK=false
          fi

          if [ `mount -t ext4 -o rw,noatime $LOOPCACHE /cache/cache_img >/dev/null 2>&1; echo $?` -ne 0 ]; then
            OK=false
          fi

          if ($OK); then
            # if mounts have succeeded, merge the images
            if [ `cp -af /cache/cache_img/. /cache/data_img >/dev/null 2>&1; echo $?` -eq 0 ]; then
              log_print "merge complete"
              OVERWRITE=false
            fi
          fi

          umount /cache/data_img
          umount /cache/cache_img
        fi
      fi

      losetup -d $LOOPDATA
      losetup -d $LOOPCACHE

      rmdir /cache/data_img
      rmdir /cache/cache_img
    fi

    if ($OVERWRITE); then
      # no /data/su.img or merge failed, replace
      log_print "replacing /data/su.img with /cache/su.img"
      mv /cache/su.img /data/su.img

      # make sure the new image is the right size
      resize
    fi

    rm /cache/su.img
  fi

  if [ ! -f "/data/su.img" ]; then
    if [ -d "/.sufrp" ]; then
      # create empty image
      make_ext4fs -l 96M -a /su -S /.sufrp/file_contexts_image /data/su.img
      chown 0.0 /data/su.img
      chmod 0600 /data/su.img
      chcon u:object_r:system_data_file:s0 /data/su.img

      # make sure the new image is the right size
      resize
    fi
  fi
fi

# do we have an APK to install ?
if [ -f "/cache/SuperSU.apk" ]; then
  cp /cache/SuperSU.apk /data/SuperSU.apk
  rm /cache/SuperSU.apk
fi
if [ -f "/data/SuperSU.apk" ]; then
  log_print "installing SuperSU APK in /data"

  APKPATH=eu.chainfire.supersu-1
  for i in `ls /data/app | grep eu.chainfire.supersu- | grep -v eu.chainfire.supersu.pro`; do
    if [ `cat /data/system/packages.xml | grep $i >/dev/null 2>&1; echo $?` -eq 0 ]; then
      APKPATH=$i
      break;
    fi
  done
  rm -rf /data/app/eu.chainfire.supersu-*

  log_print "target path: /data/app/$APKPATH"

  mkdir /data/app/$APKPATH
  chown 1000.1000 /data/app/$APKPATH
  chmod 0755 /data/app/$APKPATH
  chcon u:object_r:apk_data_file:s0 /data/app/$APKPATH

  cp /data/SuperSU.apk /data/app/$APKPATH/base.apk
  chown 1000.1000 /data/app/$APKPATH/base.apk
  chmod 0644 /data/app/$APKPATH/base.apk
  chcon u:object_r:apk_data_file:s0 /data/app/$APKPATH/base.apk

  rm /data/SuperSU.apk

  sync

  # just in case
  REBOOT=true
fi

# sometimes we need to reboot, make it so
if ($REBOOT); then
  log_print "rebooting"
  if [ "$MODE" = "post-fs-data" ]; then
    # avoid device freeze (reason unknown)
    sh -c "sleep 5; reboot" &
  else
    reboot
  fi
  exit
fi

if [ ! -d "/su/bin" ]; then
  # not mounted yet, and doesn't exist already, mount

  # fix permissions
  chown 0.0 /data/su.img
  chmod 0600 /data/su.img
  chcon u:object_r:system_data_file:s0 /data/su.img

  # losetup is unreliable pre-M
  if [ `cat /proc/mounts | grep /su >/dev/null 2>&1; echo $?` -ne 0 ]; then
    loopsetup /data/su.img
    if [ ! -z "$LOOPDEVICE" ]; then
      MOUNT=$(mount -t ext4 -o rw,noatime $LOOPDEVICE /su 2>&1)
      log_print "$MOUNT"
    fi
  fi

  # trigger mount, should also work pre-M, but on post-fs-data trigger may
  # be processed only after this script runs, causing a fallback to service launch
  if [ `cat /proc/mounts | grep /su >/dev/null 2>&1; echo $?` -ne 0 ]; then
    setprop sukernel.mount 1
    sleep 1
  fi

  # exit if all mount attempts have failed, script is likely to be called again
  if [ `cat /proc/mounts | grep /su >/dev/null 2>&1; echo $?` -ne 0 ]; then
    log_print "abort: mount failed"
    exit
  fi
fi

if [ ! -d "/su/bin" ]; then
  # empty image
  if [ -d "/.sufrp" ]; then
    /.sufrp/frp_install
  fi
fi

# if other su binaries exist, route them to ours
mount -o bind /su/bin/su /sbin/su 2>/dev/null
mount -o bind /su/bin/su /system/bin/su 2>/dev/null
mount -o bind /su/bin/su /system/xbin/su 2>/dev/null

# poor man's overlay on /system/xbin
if [ -d "/su/xbin_bind" ]; then
  cp -f -a /system/xbin/. /su/xbin_bind
  rm -rf /su/xbin_bind/su
  ln -s /su/bin/su /su/xbin_bind/su
  mount -o bind /su/xbin_bind /system/xbin
fi

# start daemon
if [ "$MODE" != "post-fs-data" ]; then
  # if launched by service, replace this process (exec)
  log_print "exec daemonsu"
  exec /su/bin/daemonsu --auto-daemon
else
  # if launched by exec, fork (non-exec) and wait for su.d to complete executing
  log_print "fork daemonsu"
  /su/bin/daemonsu --auto-daemon

  # wait for a while for su.d to complete
  if [ -d "/su/su.d" ]; then
    log_print "waiting for su.d"
    for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16; do
      # su.d finished ?
      if [ -f "/dev/.su.d.complete" ]; then
        break
      fi

      for j in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16; do
        # su.d finished ?
        if [ -f "/dev/.su.d.complete" ]; then
          break
        fi

        # sleep 240ms if usleep supported, warm up the CPU if not
        # 16*16*240ms=60s maximum if usleep supported, else much shorter
        usleep 240000
      done
    done
  fi
  log_print "end"
fi
