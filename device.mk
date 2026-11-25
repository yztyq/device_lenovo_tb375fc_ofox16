#
# TB375FC (Lenovo Xiaoxin Pad Pro 12.7 2025) device makefile
# OrangeFox fox_16.0 / vendor_boot-as-recovery
#
LOCAL_PATH := device/lenovo/tb375fc

# OrangeFox copies every file under recovery/root/** into the recovery ramdisk
# automatically, so the fstab, init.recovery.mt8792.rc and the 222 kernel
# modules under recovery/root/lib/modules do NOT need PRODUCT_COPY_FILES.
#
# Deliberately empty otherwise: this tree must not guess at packages that the
# ROM owns (TEE daemons, HALs). They come from the installed ROM.

# Only the recovery-specific fstab is forced in, to make sure a stale vendor
# fstab can never win (TW_SKIP_ADDITIONAL_FSTAB is also set in BoardConfig).
