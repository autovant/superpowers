# Contributing

Thank you for improving the GitHub Copilot adaptation of Superpowers.

## Scope

This fork focuses on GitHub Copilot compatibility, project-scoped installation, documentation accuracy, and careful synchronization with the upstream skill model. Changes should preserve the attribution and MIT license from [obra/superpowers](https://github.com/obra/superpowers).

For a change to an upstream skill's core behavior, consider proposing it upstream first. Copilot-specific tool mappings, installers, prompt files, and compatibility notes belong here when they cannot be expressed upstream cleanly.

## Before Opening a Pull Request

1. Create a focused branch from the current `main`.
2. Keep the change limited to one concern.
3. Update user-facing documentation when behavior changes.
4. Run the local quality suite:

   ```powershell
   pwsh -NoProfile -File tests/test_repository.ps1
   ```

5. Test the relevant installer in a temporary project, not in a repository with uncommitted work.
6. Review the diff for generated files, credentials, machine-specific paths, and accidental changes to upstream attribution.

## Pull Request Expectations

Describe:

- The problem being solved.
- Why the change belongs in this fork.
- The files and behavior affected.
- The validation performed.
- Any compatibility or upstream-sync risk.

Documentation-only changes still need link, code-fence, and command review. Installer changes should demonstrate install, repeat-install, and uninstall behavior while preserving pre-existing project guidance.

## Security and Privacy

Do not commit tokens, credentials, private repository details, personal paths, customer information, or production configuration. Report suspected vulnerabilities through the process in [SECURITY.md](SECURITY.md), not a public issue.

## License

By contributing, you agree that your contribution is licensed under the repository's MIT license and that existing upstream notices remain intact.
