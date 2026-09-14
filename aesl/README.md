# Reproducible image pipeline

## Release contract

The pipeline produces:

- `system.img` — Waydroid-patched LineageOS 20 ARM64;
- `vendor.img` — Waydroid Mainline vendor with Mesa enabled;
- `SHA256SUMS`;
- `source-manifest.xml` containing immutable revisions;
- `build-info.json` identifying Android R13, LineageOS 20 and the memory profile;
- artifact-derived SPDX SBOM and system/vendor NOTICE archives; and
- Android licence metadata.

Google applications are deliberately excluded. Signing and release publication
are separate protected stages; development images are not production releases.

## Maintained Android R13 profiles

Android R13 / LineageOS 20 is AESL's legacy-support lane for potential customer
requirements and qualification of existing deployments. It is not the default
baseline for a new long-support product. The ARM64 workflow exposes two named,
separately cached profiles:

| Profile | Android product | Intended use |
| --- | --- | --- |
| `standard` | `lineage_waydroid_arm64-userdebug` | Legacy systems without the 2 GB product constraint |
| `2gb` | `lineage_waydroid_aesl_2gb_arm64_only-userdebug` | Products where host Linux, graphics and Android share 2 GB |

Both profiles remain reproducible from the reviewed source lock and emit the
same evidence classes. Any commercial support period, vulnerability response
commitment or market-release decision is made for the resulting whole product,
not inferred from a successful image build. AESL's preferred 5+ year CRA
engineering baseline for new work is Android R16 / LineageOS 23.2 in the
`waydroid-product-manifest` repository.

The normal image workflow applies the reviewed container-critical patches,
including Waydroid's Android init adaptation, and produces the locked
container-compatible LineageOS system image paired with the Waydroid vendor
image. The wider optional desktop-integration patch stack remains available
through `AESL_APPLY_WAYDROID_PATCHES=true` only in a dedicated rebase lane.

## Framework laptop test lane

The **Build Android R13 / LineageOS 20 x86_64 test images** workflow builds
`lineage_waydroid_x86_64-userdebug` from the same reviewed source lock. It
uses a separate Android workspace and artifact name so it can be installed in
Waydroid on an x86_64 Linux Framework laptop without affecting the ARM64
release-image lane. Tag a reviewed revision `aesl-waydroid-x86_64-v*` to run
this lane.

## Source locking

Android is a multi-repository build. A branch name alone is not reproducible.
Run the **Resolve Android R13 / LineageOS 20 source lock** workflow when intentionally updating the
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

The maintenance and evidence boundary for these legacy builds is defined in
`aesl/CRA-MAINTENANCE.md`.
