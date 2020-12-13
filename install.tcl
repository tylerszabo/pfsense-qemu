#!/usr/bin/expect

if { [llength $argv] == 0 } {
  if { ! [file exist $::env(INSTALLER_PATH)] } {
    system wget --output-document $::env(INSTALLER_PATH) $::env(INSTALLER_URL)
  }

  set BASE_IMAGE_PATH [regsub -- ".gz$" $::env(INSTALLER_PATH) ""]
  if { ! [file exist $BASE_IMAGE_PATH]} {
    system gunzip -k $::env(INSTALLER_PATH)
  }

  set CONFIG_XML_PATH $::env(CONFIG_XML_PATH)
  set OUTPUT_PATH $::env(OUTPUT_PATH)
} else {
  set OUTPUT_PATH [lindex $argv 0]
  set BASE_IMAGE_PATH [lindex $argv 1]
  if { [llength $argv] > 2 } {
    set CONFIG_XML_PATH [lindex $argv 2]
  } else {
    set CONFIG_XML_PATH ""
  }
}

if { [string length $BASE_IMAGE_PATH] == 0 } { puts stderr "BASE_IMAGE_PATH not set"; exit }
if { [string length $OUTPUT_PATH] == 0 } { puts stderr "OUTPUT_PATH not set"; exit }

if { [file exists $OUTPUT_PATH] } { puts stderr "\"$OUTPUT_PATH\" already exists"; exit }

set INSTALLER_IMAGE_PATH "installer.qcow2"
set TARGET_IMAGE_PATH "target.qcow2"
set CONF_IMAGE_PATH "conf.img"

if { [file exist $CONFIG_XML_PATH] && [file isfile $CONFIG_XML_PATH] } {
  puts "Using config.xml \"$CONFIG_XML_PATH\""

  set CONF_VOL_PATH "conf.vfat"
  set CONF_VOL_MBYTES [expr [file size $CONFIG_XML_PATH] / 1000000 + 1]

  system dd if=/dev/zero of=$CONF_VOL_PATH bs=1M count=$CONF_VOL_MBYTES
  system mkfs.vfat $CONF_VOL_PATH

  system mmd -i $CONF_VOL_PATH ::conf
  system mcopy -i $CONF_VOL_PATH $CONFIG_XML_PATH ::conf/config.xml

  system dd if=$CONF_VOL_PATH of=$CONF_IMAGE_PATH bs=1M seek=1 count=$CONF_VOL_MBYTES
  system parted $CONF_IMAGE_PATH mklabel msdos mkpart primary fat16 1M 100%
} else {
  system touch $CONF_IMAGE_PATH
}

system qemu-img create -f qcow2 $INSTALLER_IMAGE_PATH -b $BASE_IMAGE_PATH -F raw
system qemu-img create -f qcow2 $TARGET_IMAGE_PATH 4G

log_user 0
set timeout -1

puts "Installing..."

#Start the guest VM
spawn qemu-system-x86_64 -m 512 -display none -nodefaults -serial stdio \
  -drive file=$TARGET_IMAGE_PATH,format=qcow2,id=drive-target,if=none \
  -device virtio-blk-pci,bus=pci.0,addr=0x2,drive=drive-target \
  -drive file=$INSTALLER_IMAGE_PATH,format=qcow2,id=drive-installer,if=none \
  -device virtio-blk-pci,bus=pci.0,addr=0x3,drive=drive-installer,bootindex=1 \
  -drive file=$CONF_IMAGE_PATH,format=raw,id=drive-conf,if=none \
  -device virtio-blk-pci,bus=pci.0,addr=0x4,drive=drive-conf

expect "Console type \\\[vt100\\\]: "
send "xterm\r"

expect "Copyright and distribution notice"
send "\r"

expect "Install pfSense"
send "\r"

expect "Keymap Selection"
send "\r"

expect "Partitioning"
send "\r"

expect "Partitioning"
send "\r"

expect "Partition"
expect "vtbd0"
send "\r"

expect "Partition Scheme"
send "\r"

expect "Partition Editor"
expect "vtbd0s1a*freebsd-ufs*/"
send "\r"
send "\r"

expect "Confirmation"
send "\r"

expect "Manual Configuration"
send "y"

expect -re "# $"
send "poweroff\r"
expect eof

file rename $TARGET_IMAGE_PATH $OUTPUT_PATH
