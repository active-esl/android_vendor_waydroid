# Reproducible image pipeline

## Release contract

The pipeline produces:

- `system.img` — Waydroid-patched LineageOS 20 ARM64;
- `vendor.img` — Waydroid Mainline vendor with Mesa enabled;
- `SHA256SUMS`;
- `source-manifest.xml` containing immutable revisions;
- `build-info.json` and Android licence metadata.

Google applications are deliberately excluded. Signing and release publication
are separate protected stages; development images are not production releases.

The normal image workflow applies the reviewed container-critical patches,
including Waydroid's Android init adaptation, and produces the locked
container-compatible LineageOS system image paired with the Waydroid vendor
image. The wider optional desktop-integration patch stack remains available
through `AESL_APPLY_WAYDROID_PATCHES=true` only in a dedicated rebase lane.

## Framework laptop test lane

The **Build AESL Waydroid x86_64 test images** workflow builds
`lineage_waydroid_x86_64-userdebug` from the same reviewed source lock. It
uses a separate Android workspace and artifact name so it can be installed in
Waydroid on an x86_64 Linux Framework laptop without affecting the ARM64
release-image lane. Tag a reviewed revision `aesl-waydroid-x86_64-v*` to run
this lane.

## Source locking

Android is a multi-repository build. A branch name alone is not reproducible.
Run the **Resolve Android source lock** workflow when intentionally updating the
base. Review its `source-manifest.xml` artifact and commit it as
`aesl/manifests/lineage-20-lock.xml`. Normal image builds refuse to run without
that lock.

## Runner

Image builds run on the existing self-hosted `esl-proxmox` runner. It requires
roughly 300 GB of free SSD space, at least 16 GB RAM, Git LFS, Google's `repo`
tool and the LineageOS 20 build prerequisites. The checkout and ccache
directories should be persistent between builds.

## Foundries integration

Foundries must consume a released pair by immutable version and SHA-256, rather
than downloading Waydroid's rolling SourceForge channel. Keep the system and
vendor images paired from the same Active ESL build.

## i.MX8MM hardware video decode

The ARM64 vendor image includes Android's stateful V4L2 Codec2 service and
registers `c2.v4l2.avc.decoder`. On the Jaguar screen target, the host loads
NXP's `vsiv4l2` kernel module and binds its `vsi_v4l2dec` video node into the
Waydroid container before Android starts. The matching Foundries integration
does this automatically.

Runtime acceptance requires all of the following:

1. `dumpsys media.codec` lists `c2.v4l2.avc.decoder` ahead of the Google
   software AVC decoder.
2. H.264 playback remains visible on the physical Jaguar display.
3. Codec logs name `c2.v4l2.avc.decoder` for the playback session.
4. Host tracing or driver counters show activity on `vsi_v4l2dec` while the
   clip plays.
