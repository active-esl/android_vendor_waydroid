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

The normal image workflow does not apply Waydroid's framework/core patch stack:
it produces the locked vanilla LineageOS system image paired with the Waydroid
vendor image. The sole exception is the upstream init host-UID decoder patch;
the Waydroid vendor init services require it and Android's init verifier uses
the same decoder. Set `AESL_APPLY_WAYDROID_PATCHES=true` only in a dedicated
runtime-integration lane after that broader patch stack has been rebased and
tested against the locked source manifest.

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
