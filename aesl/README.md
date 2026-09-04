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

## Source locking

Android is a multi-repository build. A branch name alone is not reproducible.
Run the **Resolve Android source lock** workflow when intentionally updating the
base. Review its `source-manifest.xml` artifact and commit it as
`aesl/manifests/lineage-20-lock.xml`. Normal image builds refuse to run without
that lock.

## Runner

Image builds require a self-hosted runner labelled `aesl-android` with roughly
300 GB of free SSD space, at least 16 GB RAM, Git LFS, Google's `repo` tool and
the LineageOS 20 build prerequisites. The checkout and ccache directories should
be persistent between builds.

## Foundries integration

Foundries must consume a released pair by immutable version and SHA-256, rather
than downloading Waydroid's rolling SourceForge channel. Keep the system and
vendor images paired from the same Active ESL build.
