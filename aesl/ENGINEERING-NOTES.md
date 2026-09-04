# Engineering evidence

This is a concise, non-confidential record of decisions and proof points. It is
not release evidence; immutable manifests, CI artifacts and hardware logs remain
authoritative.

## 2026-09-04 — First i.MX8M Mini hardware pass

- Decision: use the upstream Etnaviv DRM driver for Waydroid rather than the
  proprietary Galcore userspace/kernel pairing.
- Proof: both i.MX8M Mini GPU cores bound to Etnaviv and exposed a DRM render
  node while the Wayland compositor remained operational.
- Failure: Waydroid stopped before container startup because Android Binder was
  disabled in the host kernel. Graphics had therefore not yet been exercised by
  Android.
- Fix under test: enable the Android driver subsystem and Binder only when the
  `android-container` distribution feature is selected.
- Pipeline failure: the first complete source-lock run retained its workspace
  but failed after transient TLS disconnects from the Android source host.
- Pipeline decision: retry source sync in place so already downloaded Git
  objects are preserved; do not weaken immutable source locking.
