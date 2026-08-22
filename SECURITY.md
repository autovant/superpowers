# Security Policy

## Supported Version

Security fixes target the current `main` branch. Older commits and locally modified installations are not maintained as separate release lines.

## Reporting a Vulnerability

Please do not open a public issue for a suspected vulnerability.

Use GitHub's private vulnerability reporting flow from the repository's **Security** tab and include:

- The affected file and behavior.
- A minimal reproduction or proof of impact.
- The operating system and shell involved.
- Whether the issue affects installation, update, or uninstall behavior.
- Any suggested mitigation, if known.

Do not include real credentials, tokens, customer data, or unrelated private files. Use synthetic examples where possible.

## Security Boundary

This repository contains instruction files and project-scoped installer scripts. It does not run a hosted service or process project code by itself. The installers do write to `.github/copilot-instructions.md` and `.github/prompts/` in the current working directory, so review the target repository and commit or back up important local changes before installation.

The local validation suite provides regression coverage for installer idempotency and preservation of existing guidance. It is not a security audit of GitHub Copilot, VS Code, the model provider, or the upstream repository.
