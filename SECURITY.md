# Security policy

## Reporting a vulnerability

Use GitHub's **Report a vulnerability** action for this repository. Do not open
a public issue for an uncoordinated vulnerability and do not include secrets,
customer data or exploit material in ordinary issues or pull requests.

Include the affected revision, host interface or component, reproducible
impact and any suggested mitigation. We aim to acknowledge reports within two
working days and will coordinate disclosure after affected releases and
customers have a remediation path.

## Supported scope

`lineage-23.2-aesl` is the maintained AESL Android 16 development line. Older
branches are upstream history, not AESL-supported product releases. Product
support periods and shipped component evidence are controlled by signed
release records in the product-manifest repository.

Potentially exploited vulnerabilities are escalated immediately into the AESL
product-security process for applicable CRA Article 14 assessment. This policy
is not a Declaration of Conformity or legal advice.

## Automated review

Pull requests and scheduled repository security reviews use the AESL Preloop
Cloud flows. Preloop findings support human triage; they do not replace SBOM
vulnerability management, binary-risk assessment or runtime acceptance.
