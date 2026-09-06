# AESL vendor overlay

This directory contains Active ESL-owned content installed into the Waydroid
`vendor.img`. It is included by the product definition and currently installs
`/vendor/etc/aesl/defaults.conf`.

Use this overlay for narrowly scoped appliance configuration: device identity,
first-boot provisioning input, trusted certificates, preloaded vendor apps, or
hardware/runtime defaults. Each runtime-facing setting needs an owner, schema,
and verification method.

Do not use it to change LineageOS framework behaviour or silently enable the
broad Waydroid framework patch stack. Those changes require a separate,
lock-pinned integration lane and runtime validation.
