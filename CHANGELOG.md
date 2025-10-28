# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog, and this project adheres to Semantic Versioning.

## [0.1.0] - 2025-10-28

Initial consolidated release for the AV Searcher and docs polish.

### Added
- One‑click launcher `AVSearcher/Start-AVSearcher.bat` (hidden console, per-run ExecutionPolicy bypass).
- `StatusSource` property on AV items for clear source attribution (e.g., `DefenderModule`).
- Credits section in `README.md` (DiagnosticsViewer idea by @alessandromrc).
- `.gitattributes` with basic text normalization.

### Changed
- Consolidated all AV Searcher assets into `AVSearcher/` folder; root files are minimal shims for backward‑compat.
- Improved dark theme buttons without custom painting (Flat style, hover/pressed states, subtle borders).
- README updated with new launch paths and simple Quick Start.

### Fixed
- Startup error when setting `StatusSource` by ensuring the property exists on all objects (CIM + WMIC) and adding a defensive guard.
- Header "total product(s) found" now shows a value reliably using a null‑safe count.
- Retained crisp grid divider rendering via `CellPainting` to remove the white divider artifact.

### Removed
- Rounded button custom painting and related heavy UI code.
- Legacy/unused detection paths and clutter previously removed (extensions/process/service vendor maps, registry uninstall scan).

### Technical notes
- Antivirus enumeration via SecurityCenter2 (CIM) with WMIC fallback.
- Windows Defender ACTIVE/PASSIVE resolved by registry: `PassiveMode` and `IsServiceRunning`.
- Path handling expands environment variables and extracts .exe candidates for Open/Launch.

[0.1.0]: https://github.com/Lenalein2001/Stand-Support-tools/releases/tag/v0.1.0

## [0.1.1] - 2025-10-28

### Fixed
- Hidden launcher: `AVSearcher/Start-AVSearcher.vbs` now reliably starts the GUI with no visible console using `-WindowStyle Hidden` and hidden WSH run, and reports a clear error if `AVSearcher.ps1` is missing.

### Notes
- Prefer the VBS launcher for a fully hidden experience; use the BAT as a fallback where Windows Script Host (VBS) is disabled by policy.

[0.1.1]: https://github.com/Lenalein2001/Stand-Support-tools/compare/v0.1.0...v0.1.1
