# Contributing

Open maintained integration changes against `lineage-23.2-aesl`. Keep upstream
syncs, compatibility patches and product-policy changes in separate pull
requests.

Every pull request must identify the affected products, upstream source and
immutable revision, file-level licence and redistribution impact, SBOM and
binary-risk impact, validation performed, remaining runtime evidence and any
AI assistance. Patch series must apply strictly to the reviewed source lock.

Do not add mutable dependencies or unregistered binaries. Never include
credentials, customer data or private vulnerabilities in a pull request; use
GitHub private vulnerability reporting.

Pull requests are reviewed by CODEOWNERS and the AESL Preloop PR review flow.
Use `Assisted-by:` for disclosed AI assistance; do not assign AI a
copyright-bearing `Co-authored-by:` trailer.
