# Stand Support Tools

This repository contains tools for Stand Lua platform support and diagnostics.

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
