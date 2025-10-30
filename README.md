# Stand Support Tools

Small, zero‑install tools to help support staff gather and read diagnostics.

## What’s inside

- DiagnosticsViewer — static HTML + JS viewer for diagnostics JSON files (open directly in a browser)
- AV Searcher — Windows PowerShell GUI that shows ACTIVE vs PASSIVE antivirus

---

## DiagnosticsViewer (no install)

A standalone web viewer for Stand diagnostics JSON files.

### Quick start

1) Download the `DiagnosticsViewer/` folder
2) Double‑click `DiagnosticsViewer/index.html` to open it in your browser
3) Load a diagnostics JSON using any of these:
   - From URL: paste a direct JSON URL and click “Load JSON”
   - From file: click “Choose File” and select a `.json`
   - Drag & drop: drop a `.json` anywhere on the page

### Features

- Collapsible, readable sections for nested data
- Automatic error banners with troubleshooting guidance
- Parallel CORS proxy loading for many remote URLs (e.g., Discord CDN)
- Dark theme

### Tips & troubleshooting

- If URL loading fails, right‑click the Discord attachment → “Save link as…”, then use “Choose File” or drag & drop the saved `.json`.
- The viewer runs entirely in your browser—no install, no server.

---

## AV Searcher (Windows)

A small PowerShell GUI that clearly indicates which antivirus is ACTIVE vs PASSIVE.

### Easiest way to launch (no tech skills required)

- Double‑click `AVSearcher/Start-AVSearcher.vbs` (fully hidden console)
- Or: double‑click `AVSearcher/Start-AVSearcher.bat` (may flash a console briefly)
- Or: right‑click `AVSearcher/AVSearcher.ps1` → Run with PowerShell

### If Windows blocks it

- SmartScreen: “More info” → “Run anyway”.
- “This file came from another computer”: Right‑click → Properties → check “Unblock” → OK.
- Corporate policy: launchers use `-ExecutionPolicy Bypass` for this run only. If Windows Script Host (VBS) is disabled by policy, use the BAT launcher.

### What you’ll see

- Header shows the active product (e.g., “ACTIVE PROTECTION: …”).
- Grid lists products with status: [ACTIVE], [PASSIVE], [DISABLED], [UNKNOWN].

### Notes

- `av_searcher.bat` is legacy (reference only). Prefer the VBS launcher; use the BAT when VBS is disabled by policy.

---

## Folder structure

- `DiagnosticsViewer/` — open `index.html` directly
- `AVSearcher/AVSearcher.ps1` — main GUI script
- `AVSearcher/Start-AVSearcher.vbs` — recommended one‑click launcher (hidden console)
- `AVSearcher/Start-AVSearcher.bat` — fallback launcher (may briefly show a console)

## Credits

- DiagnosticsViewer: original idea by @alessandromrc — https://github.com/alessandromrc
