# Active ESL vendor overlay for the Waydroid image.
#
# Put device/runtime-specific configuration here. Framework changes belong in a
# separately tested integration lane, not in the reproducible vanilla system
# image build.

PRODUCT_COPY_FILES += \
    $(AESL_VENDOR_OVERLAY_PATH)/etc/aesl/defaults.conf:$(TARGET_COPY_OUT_VENDOR)/etc/aesl/defaults.conf

# The launcher is benign until Android provisions it as the device owner. Once
# provisioned, it configures itself as the persistent home activity and enters
# Lock Task mode.
PRODUCT_PACKAGES += \
    AeslKioskController
