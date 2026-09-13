# Reproducible image pipeline

## Release contract

The pipeline produces:

- `system.img` — Vanilla LineageOS 20 ARM64;
- `vendor.img` — Waydroid Mainline vendor with Mesa enabled;
- `SHA256SUMS`;
- `source-manifest.xml` containing immutable revisions;
- `build-info.json` and Android licence metadata.

Google applications are deliberately excluded. Signing and release publication
are separate protected stages; development images are not production releases.

The Jaguar ARM64 product is a single-purpose 2 GB kiosk, not an Android TV
desktop. Its reviewed device patch enables Android's low-RAM mode, uses a
128/256 MiB Dalvik growth/maximum heap, bounds the cached-process pool, applies
PSI-aware LMKD thresholds for compressed swap, disables task snapshots, and
removes the stock launcher, updater and unused consumer applications. The
Active ESL kiosk controller remains the sole HOME activity. The Linux host
provides lz4 zram; verify that independently during hardware acceptance.

The normal image workflow does not apply Waydroid's broad framework/core patch
stack: it produces the locked LineageOS system image paired with the Waydroid
vendor image. It does apply the minimal upstream runtime compatibility needed
to boot inside LXC: the ordered first-stage/mount-all init pair, the libsync ABI
export, the dynamic host-UID decoder, and non-fatal handling when the container
cannot create Android process cgroups on the host's read-only cgroup mount. Set
`AESL_APPLY_WAYDROID_PATCHES=true` only in a dedicated runtime-integration lane
after the broader patch stack has been rebased and tested against the locked
source manifest.

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

This integration deliberately uses Android's lock-pinned generic V4L2 Codec2
adapter over the NXP kernel VPU interface. It does not import NXP's full Android
multimedia/parser tree or any unpinned proprietary userspace source.

Runtime acceptance requires all of the following:

1. `dumpsys media.codec` lists `c2.v4l2.avc.decoder` ahead of the Google
   software AVC decoder.
2. H.264 playback remains visible on the physical Jaguar display.
3. Codec logs name `c2.v4l2.avc.decoder` for the playback session.
4. Host tracing or driver counters show activity on `vsi_v4l2dec` while the
   clip plays.
