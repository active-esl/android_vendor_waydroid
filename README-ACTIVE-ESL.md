# Active ESL Waydroid images

This is the Active ESL fork of
[`waydroid/android_vendor_waydroid`](https://github.com/waydroid/android_vendor_waydroid).
It retains upstream history and adds the controlled build and release machinery
under [`aesl/`](aesl/README.md).

The initial product target is a Vanilla LineageOS 20 (Android 13) ARM64 system
image paired with the Mesa-enabled Mainline vendor image for Waydroid on the
i.MX8M Mini Jaguar Screen.

Upstream changes should be merged into `lineage-20`; Active ESL release builds
must use a reviewed source lock and must not build directly from moving branch
heads.
