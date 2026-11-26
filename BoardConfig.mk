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
TARGET_SUPPORTS_64_BIT_APPS := true
TARGET_BOARD_PLATFORM := mt6897
TARGET_BOOTLOADER_BOARD_NAME := mt8792

# ---------------------------------------------------------------- boot image
# No kernel is built: the recovery reuses the GKI 6.1 kernel inside the ROM's
# boot.img, exactly like the LineageOS tree for this tablet.
TARGET_NO_KERNEL := true
BOARD_BOOT_HEADER_VERSION := 4
BOARD_KERNEL_PAGESIZE := 4096
BOARD_HEADER_SIZE := 2128
BOARD_KERNEL_BASE := 0x3fff8000
BOARD_KERNEL_OFFSET := 0x00008000
BOARD_RAMDISK_OFFSET := 0x26f08000
BOARD_TAGS_OFFSET := 0x07c88000
BOARD_DTB_OFFSET := 0x07c88000
BOARD_DTB_SIZE := 411876
# AOSP16 only knows BOARD_PREBUILT_DTBIMAGE_DIR when BOARD_INCLUDE_DTB_IN_BOOTIMG
# is true: build/make/core/Makefile runs `cat $(BOARD_PREBUILT_DTBIMAGE_DIR)/*.dtb`
# into $(PRODUCT_OUT)/dtb.img (board_config.mk:985 requires the flag to be true).
# TARGET_PREBUILT_DTB is not an AOSP variable, so dtb.img had no generating rule
# and ninja died with: "'dtb.img', needed by 'vendor_boot.img', missing and no
# known rule to make it". The single .dtb below is the stock dtb segment,
# 411,876 B, MD5 c04d985375c5ed4196d3df00a28d370d.
BOARD_PREBUILT_DTBIMAGE_DIR := $(DEVICE_PATH)/prebuilt/dtb_dir
# AOSP16 has no BOARD_VENDOR_CMDLINE: board_config.mk:317 sets
# INTERNAL_KERNEL_CMDLINE := $(BOARD_KERNEL_CMDLINE) and core/Makefile:1668
# passes it as --vendor_cmdline to mkbootimg for vendor_boot. The stock vendor_boot
# header stores exactly this string (read from the image, cmdline[2048] at offset 28).
BOARD_KERNEL_CMDLINE := bootopt=64S3,32N2,64N2
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 67108864
BOARD_INCLUDE_DTB_IN_BOOTIMG := true
# The stock vendor_ramdisk is an LZ4 legacy frame (first bytes at page offset 4096:
# 02 21 4c 18 => magic 0x184C2102), and 60+ MB of modules will not fit the 64 MiB
# vendor_boot partition unless compressed the same way. core/Makefile:1077/5923.
BOARD_RAMDISK_USE_LZ4 := true

# ---------------------------------------------------------------- vendor_boot
BOARD_USES_GENERIC_KERNEL_IMAGE := true
# 2026-11-26 实测结论（按 device 上真正进得了 recovery 的包反推）：
#   MOVE + TARGET_NO_RECOVERY 的组合会让 TWRP 资源被赶进 vendor ramdisk，而
#   TARGET_NO_KERNEL 下 $OUT/vendor_ramdisk 并不存在（mkbootfs: cannot open
#   directory）=> platform 分片只剩 4 字节、recovery 分片退化成 AOSP recovery，
#   刷进去必定进不了 recovery。
#   vendor_boot 必须是「两片」：type=1 platform（官方原片，含 222 个 .ko）+
#   type=2 recovery（TWRP/OF 根文件系统）。platform 只能来自官方 vendor_boot，
#   由 scripts/splice_platform.py 在打包时拼回去。
# BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT := true
BOARD_INCLUDE_RECOVERY_RAMDISK_IN_VENDOR_BOOT := true
# TARGET_NO_RECOVERY := true
# TW_LOAD_VENDOR_BOOT_MODULES := true
BOARD_USES_RECOVERY_AS_BOOT := false

# 官方 platform 分片（first_stage_ramdisk + lib/modules，25,863,198 B）。
# 不能由本树生成；打包脚本把它塞进 vendor_boot 的第 0 片。
BOARD_PREBUILT_PLATFORM_RAMDISK := $(DEVICE_PATH)/prebuilt/platform_ramdisk.lz4

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
# board_config.mk:803 aborts lunch (dumpvars exit status 1) when
# TARGET_COPY_OUT_VENDOR_DLKM is 'vendor_dlkm' but neither
# BOARD_PREBUILT_VENDOR_DLKMIMAGE nor BOARD_VENDOR_DLKMIMAGE_FILE_SYSTEM_TYPE
# is set; odm_dlkm is checked the same way. Recovery never builds these images,
# so only the variable's presence matters and ext4 keeps erofs build tools out
# of the dependency chain.
BOARD_VENDOR_DLKMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_ODM_DLKMIMAGE_FILE_SYSTEM_TYPE := ext4

# Verified boot: the stock vendor_boot is an AVB-signed image, so the replacement is
# signed too (AOSP test key) and padded to the 64 MiB partition.
# build/make defines NO per-partition AVB key defaults: INTERNAL_AVB_VENDOR_BOOT_
# SIGNING_ARGS only exists after _check-and-set-avb-chain-args runs, which requires
# BOARD_AVB_VENDOR_BOOT_KEY_PATH and then hard-$(error)s unless _ALGORITHM,
# _ROLLBACK_INDEX and _ROLLBACK_INDEX_LOCATION are also defined (core/Makefile:4769).
# With them unset, avbtool add_hash_footer would run with no --algorithm/--key.
BOARD_AVB_ENABLE := true
BOARD_AVB_ALGORITHM := SHA256_RSA2048
BOARD_AVB_KEY_PATH := external/avb/test/data/testkey_rsa2048.pem
BOARD_AVB_VENDOR_BOOT_KEY_PATH := $(BOARD_AVB_KEY_PATH)
BOARD_AVB_VENDOR_BOOT_ALGORITHM := $(BOARD_AVB_ALGORITHM)
BOARD_AVB_VENDOR_BOOT_ROLLBACK_INDEX := 0
BOARD_AVB_VENDOR_BOOT_ROLLBACK_INDEX_LOCATION := 1
BOARD_AVB_VENDOR_BOOTIMAGE_KEY_PATH := $(BOARD_AVB_KEY_PATH)
# No BOARD_SYSTEM_DLKMIMAGE_* here on purpose: this tablet has no separate
# system_dlkm partition (absent from the super main partition list and from the
# stock fstab). Setting it makes board_config.mk:906 abort with
# "TARGET_COPY_OUT_SYSTEM_DLKM must be set to system_dlkm image", because
# TARGET_COPY_OUT_SYSTEM_DLKM defaults to $(TARGET_COPY_OUT_SYSTEM)/dlkm.
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
# recovery/root 里不再放 222 个 .ko：它们由 platform 分片
# (prebuilt/platform_ramdisk.lz4) 提供，文件名、大小、vermagic
# 6.1.138-android14-11-g56ef1ebb4dca 已逐一对齐。放进 recovery 分片只会让它
# 从 ~30 MB 涨到 ~45 MB，64 MiB 塞不下 platform + recovery 两片。
TW_LOAD_VENDOR_MODULES := true
