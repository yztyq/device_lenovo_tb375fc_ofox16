#
# Product definition for TB375FC — OrangeFox R12 (fox_16.0)
#
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/languages_full.mk)
$(call inherit-product, vendor/twrp/config/common.mk)

DEVICE_PATH := device/lenovo/tb375fc
$(call inherit-product, $(DEVICE_PATH)/device.mk)

PRODUCT_DEVICE := tb375fc
PRODUCT_NAME := twrp_tb375fc
PRODUCT_BRAND := Lenovo
PRODUCT_MODEL := TB375FC
PRODUCT_MANUFACTURER := Lenovo
PRODUCT_RELEASE_NAME := TB375FC

# The tablet reports ro.hardware=mt8792 while ro.board.platform=mt6897.
# Keep both so init finds init.recovery.mt8792.rc.
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    ro.hardware=mt8792 \
    ro.board.platform=mt6897
