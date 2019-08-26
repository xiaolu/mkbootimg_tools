#!/system/bin/sh

MODE=$1

log_print() {
  echo "($MODE) $1"
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

SBIN=
DAEMONSU=
LOGFILE=
if [ ! -d "/su" ]; then
  log_print "/sbin mode"

  # sbin mode
  SBIN=true
  SUFILES=/data/adb/su
  DAEMONSU=/sbin/daemonsu
  LOGFILE=/sbin/.launch_daemonsu.log

  # in case of factory reset
  if [ ! -d "/data/adb" ]; then
    mkdir /data/adb
    chmod 0700 /data/adb
    restorecon /data/adb
  fi

  # cleanup /su mode
  rm -rf /data/su.img
else
  log_print "/su mode"

  # normal systemless mode
  SBIN=false
  SUFILES=/su
  DAEMONSU=/su/bin/daemonsu
  LOGFILE=/dev/.launch_daemonsu.log

  # cleanup /sbin mode
  rm -rf /data/adb/su
fi

if ($SBIN) || [ `cat /proc/mounts | grep $SUFILES >/dev/null 2>&1; echo $?` -eq 0 ]; then
  if [ -d "$SUFILES/bin" ]; then
    if [ `ps | grep -v "launch_daemonsu.sh" | grep "daemonsu" >/dev/null 2>&1; echo $?` -eq 0 ] || [ `ps -A | grep -v "launch_daemonsu.sh" | grep "daemonsu" >/dev/null 2>&1; echo $?` -eq 0 ]; then
      # nothing to do here
      log_print "abort: daemonsu already running"
      exit
    fi
  fi
fi

setprop sukernel.daemonsu.launch $MODE

if ($SBIN); then
  # make sure our SUFILES directory exists
  # not needed in /su mode, created by boot image patcher

  mkdir $SUFILES
  chown 0.0 $SUFILES
  chmod 0755 $SUFILES
  chcon u:object_r:system_file:s0 $SUFILES
fi

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

# copy boot image backups
log_print "copying boot image backups from /cache to /data"
cp -f /cache/stock_boot_* /data/. 2>/dev/null

if ($SBIN); then
  if [ -d "/data/supersu_install" ] || [ -d "/cache/supersu_install" ]; then
    log_print "merging from [/data|/cache]/supersu_install"
    cp -af /data/supersu_install/. $SUFILES
    cp -af /cache/supersu_install/. $SUFILES
    rm -rf /data/supersu_install
    rm -rf /cache/supersu_install
    log_print "merge complete"
  fi
elif [ ! -d "$SUFILES/bin" ]; then
  # not mounted yet, and doesn't exist already, merge
  log_print "$SUFILES not mounted yet"

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
      make_ext4fs -l 96M -a $SUFILES -S /.sufrp/file_contexts_image /data/su.img
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

  log_print "SUFILES path: /data/app/$APKPATH"

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

if (! $SBIN) && [ ! -d "$SUFILES/bin" ]; then
  # not mounted yet, and doesn't exist already, mount
  log_print "preparing mount"

  # fix permissions
  chown 0.0 /data/su.img
  chmod 0600 /data/su.img
  chcon u:object_r:system_data_file:s0 /data/su.img

  # losetup is unreliable pre-M
  if [ `cat /proc/mounts | grep $SUFILES >/dev/null 2>&1; echo $?` -ne 0 ]; then
    loopsetup /data/su.img
    if [ ! -z "$LOOPDEVICE" ]; then
      MOUNT=$(mount -t ext4 -o rw,noatime $LOOPDEVICE $SUFILES 2>&1)
      log_print "mount error (if any): $MOUNT"
    fi
  fi

  # trigger mount, should also work pre-M, but on post-fs-data trigger may
  # be processed only after this script runs, causing a fallback to service launch
  if [ `cat /proc/mounts | grep $SUFILES >/dev/null 2>&1; echo $?` -ne 0 ]; then
    setprop sukernel.mount 1
    sleep 1
  fi

  # exit if all mount attempts have failed, script is likely to be called again
  if [ `cat /proc/mounts | grep $SUFILES >/dev/null 2>&1; echo $?` -ne 0 ]; then
    log_print "abort: mount failed"
    exit
  fi

  log_print "mount succeeded"
fi

if [ ! -d "$SUFILES/bin" ]; then
  log_print "FRP: empty $SUFILES"
  if [ -d "/.sufrp" ]; then
    log_print "FRP: install"
    /.sufrp/frp_install
  fi
  if [ ! -d "$SUFILES/bin" ]; then
    log_print "su binaries missing, abort"
    exit 1
  fi
elif [ -f "/.sufrp/frp_date" ]; then
  OLD_DATE=$(cat /.sufrp/frp_date);
  NEW_DATE=$(cat $SUFILES/frp_date);
  log_print "FRP date check: [$OLD_DATE] vs [$NEW_DATE]"
  if [ ! "$OLD_DATE" = "$NEW_DATE" ]; then
    log_print "FRP: install"
    /.sufrp/frp_install
  fi
fi

# poor man's overlay on /system/xbin
if [ -d "$SUFILES/xbin_bind" ]; then
  log_print "preparing /system/xbin overlay"
  cp -f -a /system/xbin/. $SUFILES/xbin_bind
  rm -rf $SUFILES/xbin_bind/su
  mount -o bind $SUFILES/xbin_bind /system/xbin
  ln -s $SUFILES/bin/su $SUFILES/xbin_bind/su
fi

# restore file contexts, in case they were lost
chcon u:object_r:system_file:s0 $SUFILES
$SUFILES/bin/sukernel --restorecon $SUFILES

# poor man's overlay on /sbin
if ($SBIN); then
  log_print "preparing /sbin overlay"

  # make rootfs writable
  mount -o rw,remount rootfs /

  # this should already exist, but...
  mkdir /root
  chown 0.0 /root
  chmod 0700 /root
  chcon u:object_r:rootfs:s0 /root

  # move original /sbin
  mv /sbin/* /root/.

  # copy back entries to /sbin, we do it this way to make sure
  # both /root and /sbin have the right SELinux contexts
  cp -af /root/* /sbin/.
  restorecon /sbin/*

  # We need to use an intermediary directory outside rootfs, because on some
  # devices bind-mount rootfs->rootfs doesn't work, else we could skip this
  # part entirely and put all the files directly in /root. (6P)
  #
  # The original sbin files themselves must remain on rootfs, on some
  # devices the binaries will not execute if you place them outside rootfs.
  # (HTC10)
  #
  # On some devices, root processes cannot fork/exec when located in /data,
  # and thus the intermediary directory is placed in /dev. (Samsung *)
  #
  # The old solution of putting everything inside an image inside /data that
  # is loop-mounted of course still works (on most devices), but one of the
  # points of all this is to eliminate that image (which was originally used
  # to bypass that Samsung protection)
  rm -rf /dev/block/supersu
  mkdir /dev/block/supersu
  chmod 0755 /dev/block/supersu
  chcon u:object_r:system_file:s0 /dev/block/supersu

  # create symlinks to originals in /root
  for i in `ls /root`; do
    ln -s /root/$i /dev/block/supersu/$i
  done

  # make sure our bind becomes 0755 instead of 0750 of original /sbin
  chmod 0755 /dev/block/supersu/.

  # bind and restorecon (yes chcon twice)
  chcon u:object_r:system_file:s0 /dev/block/supersu/.
  mount -o bind /dev/block/supersu /sbin
  restorecon /sbin/*
  chcon u:object_r:system_file:s0 /dev/block/supersu/.

  # copy/link/bind su files
  for FILE in daemonsu su sukernel; do
    touch /sbin/$FILE
    mount -o bind $SUFILES/bin/$FILE /sbin/$FILE
    chcon u:object_r:system_file:s0 /sbin/$FILE
  done
  ln -s su /sbin/supolicy
  chcon u:object_r:system_file:s0 /sbin/supolicy

  # 3rd party apps can find the real path with: readlink /sbin/supersu_link
  ln -s $SUFILES /sbin/supersu_link
  chcon u:object_r:system_file:s0 /sbin/supersu_link

  # /sbin/supersu should be used to access any files or run any executable inside SuperSU's
  # directory tree. This bypasses some Samsung protections that would kick in when using
  # the real path.
  mkdir /sbin/supersu
  mount -o bind $SUFILES /sbin/supersu
  chcon u:object_r:system_file:s0 /sbin/supersu

  # we don't need these beyond this point
  rm -rf /.sufrp
  rm -rf /.subackup
  rm -rf /su

  # make rootfs read-only again
  mount -o ro,remount rootfs /
fi

# if other su binaries exist, route them to ours
if (! $SBIN); then
  log_print "bind mounting pre-existing su binaries"
  mount -o bind /su/bin/su /sbin/su 2>/dev/null
  mount -o bind /su/bin/su /system/bin/su 2>/dev/null
  if [ ! -d "$SUFILES/xbin_bind" ]; then
    mount -o bind /su/bin/su /system/xbin/su 2>/dev/null
  fi
else
  mount -o bind /sbin/su /system/bin/su 2>/dev/null
  if [ ! -d "$SUFILES/xbin_bind" ]; then
    mount -o bind /sbin/su /system/xbin/su 2>/dev/null
  fi
fi

# start daemon
if [ "$MODE" != "post-fs-data" ]; then
  # if launched by service, replace this process (exec)
  log_print "exec daemonsu"

  # save log to file
  logcat -d | grep "launch_daemonsu" > $LOGFILE
  chmod 0644 $LOGFILE

  # go
  exec $DAEMONSU --auto-daemon
else
  # if launched by exec, fork (non-exec) and wait for su.d to complete executing
  log_print "fork daemonsu"
  $DAEMONSU --auto-daemon

  # wait for a while for su.d to complete
  if [ -d "$SUFILES/su.d" ]; then
    log_print "waiting for su.d"
    for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16; do
      # su.d finished ?
      if [ -f "/dev/.su.d.complete" ] || [ -f "/sbin/.su.d.complete" ]; then
        break
      fi

      for j in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16; do
        # su.d finished ?
        if [ -f "/dev/.su.d.complete" ] || [ -f "/sbin/.su.d.complete" ]; then
          break
        fi

        # sleep 240ms if usleep supported, warm up the CPU if not
        # 16*16*240ms=60s maximum if usleep supported, else much shorter
        usleep 240000
      done
    done
  fi
  log_print "end"

  # save log to file
  logcat -d | grep "launch_daemonsu" > $LOGFILE
  chmod 0644 $LOGFILE
fi
