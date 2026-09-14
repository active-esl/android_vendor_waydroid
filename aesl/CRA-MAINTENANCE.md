# Android R13 legacy maintenance profile

Updated: 2026-09-14

Status: engineering maintenance plan; not a declaration of conformity or a
claim that a product is CRA compliant.

Android R13 / LineageOS 20 is retained for potential customers whose existing
software, peripherals or qualification constraints make migration impractical.
New AESL products should normally start from Android R16 / LineageOS 23.2,
which is the maintained 5+ year platform baseline.

## Build matrix

The `standard` and `2gb` ARM64 profiles are separate product identities. A
release record must retain the profile, exact source lock, image hashes and
board acceptance result. A 2 GB claim additionally requires a test with the
Waydroid container limited to 2 GiB while Linux and graphics services remain
active; merely setting Android properties is insufficient evidence.

## Evidence emitted by CI

Every admitted build must contain:

- `system.img` and its paired `vendor.img`;
- immutable `source-manifest.xml` and `build-info.json`;
- `SHA256SUMS` covering every delivered file;
- artifact-derived `sbom.spdx.json`;
- system and vendor NOTICE archives; and
- generated installed-file and licence inputs where available.

CI build success is only reproducibility and supply-chain evidence. Customer
release still requires product classification, a vulnerability and binary-risk
decision, secure update and rollback proof, runtime security testing, declared
support dates, and board-specific acceptance evidence.

## Legacy-support decision

R13 security fixes are accepted only onto its immutable maintenance line and
must rebuild both profiles affected by the change. Before committing to a
customer support period, AESL must confirm upstream patch availability,
toolchain viability, CI capacity, BSP/vendor redistribution rights and test
hardware for that entire period. Unsupported optional binaries are managed as
documented exceptions rather than silently added to the image.
