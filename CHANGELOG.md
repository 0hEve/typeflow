# Changelog

All notable changes to TypeFlow are documented here.

## 0.1.4 - 2026-08-25

### Changed

- Randomize the target pace and rhythm independently for every keystroke.
- Remove delay clipping that made fast and slow keystrokes feel too uniform.
- Treat the configured WPM range as the average base pace while preserving natural variation.

## 0.1.3 - 2026-08-25

### Fixed

- Keep incomplete numeric input local to its field until it is submitted or loses focus.
- Validate a range by adjusting only the field being edited, never its paired minimum or maximum.

### Documentation

- Explain how randomized keyboard-adjacent corrections are generated and repaired.

## 0.1.2 - 2026-08-25

### Changed

- Make every numeric setting directly editable while retaining stepper controls.
- Remove arbitrary upper limits from speed, correction interval, and paragraph timing values.
- Keep range settings valid by ensuring each minimum remains below its maximum.

## 0.1.1 - 2026-08-25

### Changed

- Only show Accessibility guidance when access is missing; granted access now returns to the normal ready instruction without a success status.

## 0.1.0 - 2026-08-25

### Added

- Native macOS menu-bar interface for pasted text.
- Global Control–Option–Command–T start, pause, and resume hotkey.
- Configurable typing-speed, correction, retry, and paragraph-pause ranges.
- Fixed or random paragraph pause timing.
- Accessibility permission guidance and safe menu countdown.
- Deterministic policy checks and release packaging scripts.
