# AESL Kiosk Controller

`AeslKioskController` is a vendor-packaged Android home activity and device
owner controller. It is intentionally non-locking until explicit Android
device-owner provisioning succeeds.

Once provisioned, it:

- becomes the persistent Android Home activity;
- permits only itself in Lock Task mode;
- hides system navigation and disables the status bar.

This first slice is a controller/launcher, not the final appliance UI. The
next slice replaces its status screen with the selected AESL experience and
adds an authenticated maintenance exit. Kiosk deployment must also disable or
authenticate host-side debug/maintenance paths; Lock Task does not secure a
host with unrestricted ADB access.
