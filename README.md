# Stand Support Tools

Tools to assist support staff with troubleshooting and diagnostics.

## AV Searcher (Windows)

A small Windows PowerShell GUI that shows which antivirus is ACTIVE vs PASSIVE and provides quick actions.

### Easiest way to launch (no tech skills required)

- Double‑click `AVSearcher/Start-AVSearcher.vbs` (fully hidden console)
- Or: double‑click `AVSearcher/Start-AVSearcher.bat` (may flash a console briefly)
- Or: right‑click `AVSearcher/AVSearcher.ps1` → Run with PowerShell

### If Windows blocks it

- SmartScreen: click “More info” → “Run anyway”.
- “This file came from another computer”: Right‑click the file → Properties → check “Unblock” → OK.
- Corporate policy blocking scripts: the launchers use `-ExecutionPolicy Bypass` for this run only. If still blocked, run as an administrator or contact IT. If Windows Script Host (VBS) is disabled by policy, use the BAT launcher.

### What you’ll see

- Header shows the active product (e.g., “ACTIVE PROTECTION: Avast …”).
- Grid lists antivirus products with status: [ACTIVE], [PASSIVE], [DISABLED], [UNKNOWN].

## DiagnosticsViewer

A standalone web-based viewer for Stand diagnostics JSON files.

### Requirements

- Any modern web browser (Chrome, Firefox, Edge, Safari)
- No installation or dependencies required

### Usage

1. Download the `DiagnosticsViewer` folder
2. Open `DiagnosticsViewer/index.html` in your web browser
3. Load a diagnostics JSON file using one of these methods:
   - **From URL**: Paste the JSON file URL in the sidebar and click "Load JSON"
   - **From local file**: Click "Choose File" and select your `.json` file

### Features

- View structured diagnostics data with collapsible sections
- Automatic error detection with troubleshooting guidance
- Support for remote URLs (Discord CDN, etc.)
- Dark theme for comfortable viewing

### Troubleshooting

If you cannot load a remote URL, download the JSON file first and use the local file option instead.

### Notes

- `av_searcher.bat` is a legacy script kept for reference. Prefer the PowerShell GUI (`AVSearcher/AVSearcher.ps1`) using `AVSearcher/Start-AVSearcher.vbs` (fully hidden). If VBS is disabled by policy, use `AVSearcher/Start-AVSearcher.bat`.

### Folder structure

- `AVSearcher/AVSearcher.ps1` — main GUI script
- `AVSearcher/Start-AVSearcher.vbs` — recommended one‑click launcher (hidden console)
- `AVSearcher/Start-AVSearcher.bat` — fallback launcher (may briefly show a console)

## Credits

- DiagnosticsViewer: original idea by @alessandromrc — https://github.com/alessandromrc
