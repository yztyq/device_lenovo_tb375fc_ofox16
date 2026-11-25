#!/bin/sh
# OrangeFox build variables for TB375FC.
# FOX_* must be exported as environment variables before lunch.

export FOX_BUILD_DEVICE=TB375FC
export FOX_DEVICE=TB375FC

# This tablet has no standalone recovery partition: the recovery is the
# "recovery" ramdisk fragment of vendor_boot (header v4). Verified from the
# stock image: vendor_ramdisk_table holds 2 entries, type 0x2 name=recovery.
export FOX_VENDOR_BOOT_RECOVERY=1

# A/B device with virtual A/B (compression), dynamic partitions in super.
export FOX_VIRTUAL_AB_DEVICE=1
export FOX_AB_DEVICE=1

export FOX_USE_BASH_SHELL=1
export FOX_USE_NANO_EDITOR=1
export FOX_USE_TAR_BINARY=1
export FOX_USE_SED_BINARY=1
export FOX_DELETE_INITD_ADDON=1
export FOX_ENABLE_APP_MANAGER=1

export TARGET_ARCH=arm64

# Build:
#   source build/envsetup.sh
#   lunch twrp_tb375fc-bp2a-eng
#   mka vendorbootimage
