#
# Copyright (C) 2021 The Waydroid project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# HIDL
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/hosthals.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/hosthals.xml

# Host-AIDL passthrough allowlist
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/hostaidls.conf:$(TARGET_COPY_OUT_SYSTEM)/etc/hostaidls.conf

# Init
PRODUCT_PACKAGES += \
    init.waydroid.rc

# Dummy libnfc-nci.conf
PRODUCT_PACKAGES += \
    libnfc-nci.conf

# Properties
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/waydroid.prop:$(TARGET_COPY_OUT_VENDOR)/waydroid.prop

# Active ESL product-owned vendor configuration. Keep this limited to vendor
# content so the locked LineageOS system image remains a separately reusable
# vanilla artifact.
AESL_VENDOR_OVERLAY_PATH := $(LOCAL_PATH)/aesl/overlays/vendor
include $(LOCAL_PATH)/aesl/overlays/vendor/aesl-vendor.mk

# Jaguar i.MX8MM hardware video decode. The host exposes NXP's stateful
# vsi_v4l2dec node to the ARM64 container; this Codec2 service presents it to
# Android MediaCodec as c2.v4l2.avc.decoder.
ifneq ($(filter %_waydroid_arm64 %_waydroid_arm64_only,$(TARGET_PRODUCT)),)
PRODUCT_SOONG_NAMESPACES += external/v4l2_codec2

PRODUCT_PACKAGES += \
    android.hardware.media.c2@1.0-service-v4l2 \
    libc2plugin_store

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/aesl/imx8mm-codec2/media_codecs_c2.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_c2.xml \
    $(LOCAL_PATH)/aesl/imx8mm-codec2/codec2.vendor.ext.policy:$(TARGET_COPY_OUT_VENDOR)/etc/seccomp_policy/codec2.vendor.ext.policy \
    $(LOCAL_PATH)/aesl/imx8mm-codec2/manifest_media_c2.xml:$(TARGET_COPY_OUT_VENDOR)/etc/vintf/manifest/aesl_media_c2.xml

PRODUCT_PROPERTY_OVERRIDES += \
    ro.vendor.v4l2_codec2.decode_concurrent_instances=1 \
    debug.stagefright.c2-poolmask=0xfc0000
endif

PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.setupwizard.mode=DISABLED

# PC mode
PRODUCT_PACKAGES += \
    pc.xml
