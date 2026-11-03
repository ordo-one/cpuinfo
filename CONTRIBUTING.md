# Contributing to cpuinfo

Thank you for your interest in contributing!

## Building and Testing

```bash
swift build
swift test
```

## Updating Vendored Sources

The C sources from [pytorch/cpuinfo](https://github.com/pytorch/cpuinfo) are vendored in `Sources/_cpuinfo/`. To update them:

```bash
./Scripts/update-cpuinfo.sh          # update to latest upstream
./Scripts/update-cpuinfo.sh <SHA>    # pin to a specific commit (full 40-character SHA)
```

The script copies fresh sources, diffs the build files to surface source-list changes, and runs a local build. If upstream adds or removes source files, update the shim files in `Sources/_cpuinfo/shims/` to match.

### PR workflow for vendor updates

1. Run the update script
2. Check for source file additions/removals in the diff output
3. Update shim files if needed
4. Run `swift build` and `swift test`. The tests fail on a new microarchitecture value, and on a new ARM or x86 ISA query that the Swift sources don't call and the allow-list doesn't name:
   - a new `cpuinfo_uarch_*` value needs a `Microarchitecture` case with a description
   - a new ARM or x86 `cpuinfo_has_*` query needs a flag on `ARMFeatures` or `X86Features` (decoded with `decodeFlag` and printed by `lscpu`), or an entry in `ISATests.leftOut` if it is left out on purpose
5. Refresh the `lscpu` sample output in the README
6. Include the upstream commit SHA in the PR description

## Upstream Issues

Issues related to CPU detection, microarchitecture matching, or capability flags should be reported to the upstream [pytorch/cpuinfo](https://github.com/pytorch/cpuinfo) project. This package is a Swift wrapper and does not modify the upstream detection logic.

## Code Style

- Follow existing Swift conventions in the codebase
- All public types should be value types (`struct`) and `Sendable`
- Read C pointers only in initializers and the helpers in `Sources/CpuInfo/Internal/BridgeHelpers.swift`; never store one in a public type

## Pull Requests

- Keep PRs focused on a single change
- Include a clear description of what and why
- Ensure `swift build` and `swift test` pass before submitting

### PR titles and releases

PR titles follow [Conventional Commits](https://www.conventionalcommits.org) and become the squash-merge commit message, e.g. `fix(patch): Handle offline CPUs`. Only the `patch`, `minor`, `major` and `hotfix` scopes cut a release; any other title, such as `docs: ...` or `ci: ...`, merges without one.

## Contributor License

By submitting a pull request, you represent that you have the right to license your
contribution to Ordo One AB and the community, and agree that your contribution
is licensed under the Apache License 2.0 that covers this project.

## Code of Conduct

This project has adopted the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md).
Please report unacceptable behavior to the project maintainers.
