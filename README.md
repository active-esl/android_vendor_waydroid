# AESL Waydroid vendor integration

## Repository role

This repository is the Android **vendor-integration layer** shared by AESL
Waydroid products. Its name follows Android's standard
`android_vendor_<vendor>` convention so the fork remains straightforward to
compare and rebase against Waydroid upstream.

It owns the generic Waydroid product makefile, host HAL and AIDL declarations,
container properties, SELinux integration, compatibility patch series and the
licence material for components introduced here. It does not own:

- the complete Android source lock or release workflows;
- board product definitions and memory profiles; or
- NXP kernel, bootloader, GPU/media firmware or Yocto host integration.

Those responsibilities are separated between
[`active-esl/waydroid-product-manifest`](https://github.com/active-esl/waydroid-product-manifest),
[`active-esl/android_device_waydroid_waydroid`](https://github.com/active-esl/android_device_waydroid_waydroid)
and the Dynamic Devices BSP/Yocto repositories respectively.

## Maintained line and supply-chain policy

The maintained AESL Android 16 integration line is `lineage-23.2-aesl`.
Android versions and board profiles belong to controlled branches and products,
not to the repository name.

Every non-source component introduced through this repository must be pinned,
licensed and represented in the delivered-artifact SBOM and companion binary
risk register. A successful build is integration evidence only; it is not a
declaration of runtime acceptance, five-year support or CRA conformity.
