#
# BoardConfig for Lenovo Xiaoxin Pad Pro 12.7 2025 (TB375FC)
# OrangeFox R12 (fox_16.0 branches) — vendor_boot-as-recovery
#
# Every number below was measured from the official package in
# F:\YX\TB375FC_ZUX_1.1.04.287_Tool\image (Android 15, ZUXOS 1.1.04.287):
#   vendor_boot.img 67,108,864 B, MD5 E60D9F853E08CDE9D099EA1143D760F8
#   header v4, page 4096, header_size 2128
#   kernel_addr 0x40000000 / ramdisk_addr 0x66f00000
#   tags_addr 0x47c80000 / dtb_addr 0x47c80000
#   dtb_size 411,876 (prebuilt/dtb, MD5 c04d985375c5ed4196d3df00a28d370d)
#   vendor_boot_a partition = 0x4000000 (64 MiB), verified by fastboot getvar
#
DEVICE_PATH := device/lenovo/tb375fc

# ---------------------------------------------------------------- architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-2a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := cortex-a715
TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-2a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := generic
TARGET_USES_64_BIT_BINDER := true
TARGET_SUPPORTS_64_BIT_APPS := true
TARGET_BOARD_PLATFORM := mt6897
TARGET_BOOTLOADER_BOARD_NAME := mt8792

# ---------------------------------------------------------------- boot image
# No kernel is built: the recovery reuses the GKI 6.1 kernel inside the ROM's
# boot.img, exactly like the LineageOS tree for this tablet.
TARGET_NO_KERNEL := true
BOARD_BOOT_HEADER_VERSION := 4
BOARD_PAGE_SIZE := 4096
BOARD_HEADER_SIZE := 2128
BOARD_KERNEL_BASE := 0x3fff8000
BOARD_KERNEL_OFFSET := 0x00008000
BOARD_RAMDISK_OFFSET := 0x26f08000
BOARD_TAGS_OFFSET := 0x07c88000
BOARD_DTB_OFFSET := 0x07c88000
BOARD_DTB_SIZE := 411876
TARGET_PREBUILT_DTB := $(DEVICE_PATH)/prebuilt/dtb
BOARD_VENDOR_CMDLINE := bootopt=64S3,32N2,64N2
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 67108864
BOARD_INCLUDE_DTB_IN_BOOTIMG := true

# ---------------------------------------------------------------- vendor_boot
BOARD_USES_GENERIC_KERNEL_IMAGE := true
BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT := true
BOARD_INCLUDE_RECOVERY_RAMDISK_IN_VENDOR_BOOT := true
TARGET_NO_RECOVERY := true
TW_LOAD_VENDOR_BOOT_MODULES := true
BOARD_USES_RECOVERY_AS_BOOT := false

# ---------------------------------------------------------------- partitions
BOARD_SUPER_PARTITION_SIZE := 9126805504
BOARD_SUPER_PARTITION_GROUPS := main
BOARD_MAIN_SIZE := 9122611200
BOARD_MAIN_PARTITION_LIST := odm odm_dlkm product system system_ext vendor vendor_dlkm
BOARD_USES_METADATA_PARTITION := true
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := f2fs
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_ODMIMAGE_FILE_SYSTEM_TYPE := erofs
TARGET_USES_EROFS := true
TARGET_COPY_OUT_VENDOR := vendor
TARGET_COPY_OUT_PRODUCT := product
TARGET_COPY_OUT_SYSTEM_EXT := system_ext
TARGET_COPY_OUT_ODM := odm
TARGET_COPY_OUT_VENDOR_DLKM := vendor_dlkm
TARGET_COPY_OUT_ODM_DLKM := odm_dlkm

# ---------------------------------------------------------------- crypto
# userdata: F2FS, FBE v2 (aes-256-xts) + metadata encryption through
# dm-default-key. Confirmed on device: ro.crypto.state=encrypted,
# ro.crypto.type=file.
TW_INCLUDE_CRYPTO := true
TW_INCLUDE_CRYPTO_FBE := true
TW_INCLUDE_FBE_METADATA_DECRYPT := true
TW_USE_FSCRYPT_POLICY := 2
TW_INCLUDE_EROFS := true
TW_INCLUDE_FS_TOOLS := true
TW_INCLUDE_REPACKTOOLS := true
TW_EXCLUDE_DEFAULT_USB_INIT := true
TW_SKIP_ADDITIONAL_FSTAB := true
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery/root/system/etc/recovery.fstab

# do NOT fake the patch level, KeyMint binds key blobs to the real values.
# These are the values the installed ZUXOS 1.1.04.287 ROM actually reports:
#   ro.build.version.security_patch        = 2025-09-05
#   ro.vendor.build.security_patch         = 2024-10-05
#   ro.build.version.release               = 15
PLATFORM_SECURITY_PATCH := 2025-09-05
PLATFORM_VERSION := 15
PLATFORM_VERSION_LAST_STABLE := 15

# ---------------------------------------------------------------- ui
TW_THEME := portrait_hdpi
TW_DEFAULT_LANGUAGE := zh_CN
TW_EXTRA_LANGUAGES := true
TW_INCLUDE_NTFS_3G := true
TW_INCLUDE_FUSE_EXFAT := true
TW_INCLUDE_FUSE_NTFS := true
TW_USE_TOOLBOX := true
TW_INCLUDE_FASTBOOTD := true
TW_NO_HAPTICS := true
TW_CUSTOM_CPU_TEMP_PATH := "/sys/class/thermal/thermal_zone8/temp"
TW_MAX_BRIGHTNESS := 2047
TW_DEFAULT_BRIGHTNESS := 300
TW_DEVICE_VERSION := TB375FC-ofox16

# Landscape panel 2944x1840 is handled by OrangeFox's own rotation switch.
# Do NOT set TW_ROTATION or RECOVERY_TOUCHSCREEN_* — they override or fight it.
OF_LANDSCAPE_MODE := 1
OF_SCREEN_H := 2304
OF_NO_REFLASH_CURRENT_ORANGEFOX := 1
OF_USE_MAGISKBOOT := 1
OF_USE_MAGISKBOOT_FOR_ALL_PATCHES := 1
OF_QUICK_BACKUP_LIST := /boot;
OF_UNMOUNT_SDCARD_ON_REBOOT := 1

# ---------------------------------------------------------------- ab / vab
AB_OTA_UPDATER := true
TW_INCLUDE_LOGICAL := odm odm_dlkm product system system_ext vendor vendor_dlkm
TW_EXCLUDE_TWRPAPP := true
TARGET_OTA_ASSERT_DEVICE := tb375fc,TB375FC

# ---------------------------------------------------------------- toolbox
TWRP_INCLUDE_LOGCAT := true
TARGET_USES_LOGD := true
TW_INCLUDE_CRYPTO_FBE_ICE := true
TW_EXCLUDE_LPDUMPLITE := true

# ---------------------------------------------------------------- modules / blobs
# The 222 modules live in recovery/root/lib/modules and OrangeFox packs them
# into the recovery ramdisk automatically; there is no prebuilt/modules dir in
# this tree on purpose. TW_LOAD_VENDOR_MODULES covers the ROM-side modules that
# the bootloader exposes through vendor_boot for normal-boot paths.
TW_LOAD_VENDOR_MODULES := true
