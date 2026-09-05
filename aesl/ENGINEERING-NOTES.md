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
- Pipeline follow-up: the retained checkout filled its 400 GB dataset and left
  some project worktrees partially checked out. The dedicated CT101 `/yocto`
  dataset was expanded to 800 GB, and source sync now forces checkout repair
  while continuing to reuse downloaded Git objects.
- Proof: source-lock run `33956272488` completed successfully from commit
  `583e5aa`; artifact `lineage-20-source-lock-583e5aa47fca4509ba0e878d5d35e1a6d2120c5c`
  contains 1,254 projects, each pinned to a 40-hex commit revision. Manifest
  SHA-256: `2de1771c3efc77e3c292b6d06ac26813eda986d601ffab18f1e8adf73e578abb`.
- Image-build run `33957198264` exposed that copying the flattened lock into
  the upstream manifest checkout causes `repo init` to reapply obsolete
  remove-project directives. Builds now load the reviewed XML through repo's
  standalone-manifest mode and sync only its pinned project revisions.
