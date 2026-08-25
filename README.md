# TypeFlow

[![CI](https://github.com/0hEve/typeflow/actions/workflows/ci.yml/badge.svg)](https://github.com/0hEve/typeflow/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/0hEve/typeflow?include_prereleases)](https://github.com/0hEve/typeflow/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

TypeFlow is a native macOS menu-bar app that types pasted text into the field
under your cursor. It varies its pace, adds brief pauses, and can make plausible
nearby-key mistakes before correcting them with backspace.

Everything is initiated by you: TypeFlow starts, pauses, and resumes only through
its menu or global hotkey.

## Install

```sh
brew tap 0hEve/typeflow https://github.com/0hEve/typeflow.git
brew install --cask 0hEve/typeflow/typeflow
```

The first command registers this repository as the TypeFlow tap. Homebrew then
installs `TypeFlow.app` in `/Applications`; the first installation may ask you
to trust the cask.

If you previously used the separate `homebrew-typeflow` repository, switch the
existing tap to this repository once before updating:

```sh
brew untap 0hEve/typeflow
brew tap 0hEve/typeflow https://github.com/0hEve/typeflow.git
brew update
```

Alternatively, download the latest ZIP from [GitHub Releases](https://github.com/0hEve/typeflow/releases),
unzip it, and move `TypeFlow.app` to `/Applications`.

The beta is ad-hoc signed but not Apple-notarized. On first launch, macOS may ask
you to confirm that you want to open it. Right-click `TypeFlow.app`, select
**Open**, then confirm **Open**. You do not need to disable Gatekeeper.

Uninstall TypeFlow with `brew uninstall --cask typeflow`. To remove its saved
preferences too, use `brew uninstall --zap --cask typeflow`.

## Features

- Global **Control–Option–Command–T** start, pause, and resume hotkey.
- Configurable WPM range used as the average base pace, with fresh timing
  variation for every keystroke.
- Optional corrections using nearby US QWERTY keys, duplicated letters, or
  adjacent transpositions.
- Configurable minimum and maximum words between corrections.
- Configurable chance of making a second mistake before correcting the word.
- Random or fixed paragraph pauses, with a default random range of 10–30 seconds.
- Three-second menu countdown so you can return focus to the destination field.
- Draft, progress, and settings persistence between launches.

### How corrections work

TypeFlow chooses a random interval from your **Words between corrections** range.
When the interval is reached, it creates a plausible typo by substituting a
nearby key on a US QWERTY keyboard, duplicating a letter, or swapping two
adjacent letters. It pauses briefly, backspaces the typo, and types the correct
word. The **Second mistake chance** controls whether it makes another failed
attempt before correcting the word.

## Requirements

- macOS 13 Ventura or later.
- Apple silicon for the prebuilt beta. Building from source uses your Mac's
  current architecture.
- Accessibility permission to send keystrokes to the active application.

## Use

1. Open TypeFlow and select its keyboard icon in the menu bar.
2. Paste the text you want to type.
3. Select **Grant access** and enable TypeFlow in **System Settings → Privacy &
   Security → Accessibility**.
4. Select your destination field and press **Control–Option–Command–T**.
5. Press the same hotkey to pause or resume.

The menu's start and resume buttons use a three-second countdown. Opening the
menu while typing pauses the run so keystrokes cannot land in TypeFlow's own
editor. **Stop and reset** returns progress to the beginning while preserving
the pasted draft.

## Settings

Open TypeFlow from the menu bar and select **Settings**.

| Setting | Default | Behavior |
| --- | --- | --- |
| Typing speed | 40–60 WPM | Sets the average base pace. Every keystroke varies, and the minimum must remain below the maximum. |
| Natural corrections | On | Enables plausible mistakes and backspace correction. |
| Words between corrections | 5–15 | Chooses a new random interval after each correction. |
| Second mistake chance | 20% | Controls how often a word gets a second failed attempt before correction. |
| Paragraph pauses | On | Detects a paragraph when the source contains a blank line. |
| Paragraph timing | Range, 10–30 seconds | Chooses a random delay, or can be changed to a fixed duration. |

Settings apply when the next run starts. Stop and reset before restarting if you
change settings while a draft is paused. Select any numeric value to type it
directly, or use its stepper. Speed, correction-interval, and pause values have
no arbitrary upper cap.

The WPM range controls ordinary keystroke pacing. Enabled corrections,
backspacing, punctuation reactions, short thinking pauses, and paragraph pauses
add time on top, so a full passage can finish below the selected base WPM.

## Build from source

TypeFlow has no third-party dependencies. Install Apple's Command Line Tools,
clone the repository, then run:

```sh
git clone https://github.com/0hEve/typeflow.git
cd typeflow
./scripts/check_policy.sh
./scripts/package_app.sh
open ./dist/TypeFlow.app
```

Create a versioned release archive with:

```sh
./scripts/package_release.sh
```

The scripts compile the Swift package, build a standard `.app` bundle, ad-hoc
sign it, and create a ZIP suitable for GitHub Releases.

### Updating the Homebrew cask

The Homebrew cask lives in this repository at `Casks/typeflow.rb`. Each release
must update its `version` and `sha256`. Validate it with:

```sh
brew style Casks/typeflow.rb
brew audit --cask --strict 0hEve/typeflow/typeflow
brew fetch --cask 0hEve/typeflow/typeflow
```

## Known limitations

- Resume uses TypeFlow's saved character position. It does not inspect or
  reconcile destination text edited while paused.
- Mistake adjacency currently follows a US QWERTY layout.
- Some secure or protected text fields may reject synthetic keyboard events.
- The prebuilt beta is not notarized with an Apple Developer ID.
- Because the beta is ad-hoc signed, macOS may require Accessibility permission
  to be removed and granted again after an upgrade changes the app binary.

## Contributing

Issues and focused pull requests are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md)
before submitting a change. Security reports should follow [SECURITY.md](SECURITY.md).

## License

TypeFlow is available under the [MIT License](LICENSE).
