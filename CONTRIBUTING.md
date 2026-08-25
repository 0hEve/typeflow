# Contributing to TypeFlow

Thanks for helping improve TypeFlow. Keep changes focused, native, and easy to
verify.

## Development setup

TypeFlow requires macOS 13 or later and Apple's Command Line Tools.

```sh
git clone https://github.com/0hEve/typeflow.git
cd typeflow
git switch -c your-change
./scripts/check_policy.sh
swift build -c debug
```

## Pull requests

1. Open an issue first for substantial behavior or interface changes.
2. Keep each pull request to one cohesive change.
3. Add a deterministic policy check for changes to timing, ranges, or mistakes.
4. Run `./scripts/check_policy.sh` and a release build before opening the PR.
5. Explain the user-visible behavior, verification performed, and remaining
   limitations in the PR description.

Use native macOS frameworks and the Swift standard library when possible. Never
commit credentials, personal text, local preferences, build output, or packaged
applications.

## Accessibility

Preserve keyboard navigation, visible labels, VoiceOver names, and the explicit
start/pause model. TypeFlow must never begin sending keystrokes merely because it
launched or because a draft changed.
