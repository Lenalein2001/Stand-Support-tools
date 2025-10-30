# AVSearcher - Antivirus Detection Tool (lean)
# Detects installed antivirus software using multiple lightweight methods
# Provides a small GUI with options to open program locations or launch the AV UI

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing


function Get-AVFromSecurityCenter {
    $avList = @()
    try {
        $avProducts = Get-CimInstance -Namespace "root\SecurityCenter2" -ClassName "AntiVirusProduct" -ErrorAction SilentlyContinue
        if (-not $avProducts -or $avProducts.Count -eq 0) {
            # Fallback to legacy WMIC if CIM isn't available (older systems / policy-restricted)
            return Get-AVFromSecurityCenterWmic
        }
        foreach ($av in $avProducts) {
            $state = $av.productState
            # Decode the product state bits
            # Bits 8-11 (0x1000): AV enabled/disabled
            $enabled = ($state -band 0x1000) -ne 0

            # For non-Defender vendors, treat Enabled=true as ACTIVE (PASSIVE concept mainly applies to Defender)
            # Defender's passive/active state is handled later via registry override.
            $actualStatus = if ($enabled) { $true } else { $false }
            
            $avList += [PSCustomObject]@{
                Name = $av.displayName
                Path = $av.pathToSignedReportingExe
                Enabled = $actualStatus
                Source = "SecurityCenter2"
                StatusSource = $null
            }
        }
    }
    catch {
        Write-Warning "Could not query SecurityCenter2: $_"
    }
    return $avList
}

# WMIC fallback for SecurityCenter2 (handles older environments where CIM may be blocked)
function Get-AVFromSecurityCenterWmic {
    $results = @()
    try {
        $args = @('/node:localhost','/namespace:\\root\SecurityCenter2','path','AntiVirusProduct','get','displayName,productState,pathToSignedReportingExe','/format:list')
        $raw = & wmic @args 2>$null
        if (-not $raw) { return @() }
        $block = @{}
        foreach ($line in $raw) {
            if ([string]::IsNullOrWhiteSpace($line)) {
                if ($block.ContainsKey('displayName')) {
                    $name = $block['displayName']
                    $path = if ($block.ContainsKey('pathToSignedReportingExe')) { $block['pathToSignedReportingExe'] } else { 'N/A' }
                    $stateVal = 0
                    if ($block.ContainsKey('productState')) { [void][int]::TryParse($block['productState'], [ref]$stateVal) }
                    $enabled = ($stateVal -band 0x1000) -ne 0
                    $results += [PSCustomObject]@{
                        Name = $name
                        Path = $path
                        Enabled = if ($enabled) { $true } else { $false }
                        Source = 'SecurityCenter2 (WMIC)'
                        StatusSource = $null
                    }
                }
                $block = @{}
                continue
            }
            $parts = $line -split '=', 2
            if ($parts.Length -eq 2) { $block[$parts[0].Trim()] = $parts[1].Trim() }
        }
        # Flush last block if needed
        if ($block.Count -gt 0 -and $block.ContainsKey('displayName')) {
            $name = $block['displayName']
            $path = if ($block.ContainsKey('pathToSignedReportingExe')) { $block['pathToSignedReportingExe'] } else { 'N/A' }
            $stateVal = 0
            if ($block.ContainsKey('productState')) { [void][int]::TryParse($block['productState'], [ref]$stateVal) }
            $enabled = ($stateVal -band 0x1000) -ne 0
            $results += [PSCustomObject]@{
                Name = $name
                Path = $path
                Enabled = if ($enabled) { $true } else { $false }
                Source = 'SecurityCenter2 (WMIC)'
                StatusSource = $null
            }
        }
    }
    catch {
        # Ignore WMIC errors (WMIC may be absent on some newer Windows builds)
        return @()
    }
    return $results
}

# Returns Defender status by reading PassiveMode registry value
function Get-DefenderStatus {
    try {
        $passiveModeValue = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows Defender' -Name 'PassiveMode' -ErrorAction SilentlyContinue).PassiveMode
        $serviceRunning = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows Defender' -Name 'IsServiceRunning' -ErrorAction SilentlyContinue).IsServiceRunning
        
        # PassiveMode=1 means Defender is in passive mode
        if ($passiveModeValue -eq 1) { return 'Passive' }
        
        # PassiveMode=0 or not set, check if service is running
        if ($serviceRunning -eq 1) { return $true }
        
        # If service not running, disabled
        if ($serviceRunning -eq 0) { return $false }
        
        return $null
    }
    catch {
        return $null
    }
}

# Path helpers (shared)
function Expand-PathString([string]$p) {
    if (-not $p) { return $null }
    $t = $p.Trim('"')
    return [System.Environment]::ExpandEnvironmentVariables($t)
}

function Get-ExeCandidateFromString([string]$s) {
    if (-not $s) { return $null }
    $expanded = Expand-PathString $s
    if ($expanded -match '"?([^"\s]+\.exe)"?') { return $matches[1] }
    return $null
}

function Open-AVLocation {
    param($path)
    if (-not $path -or $path -eq "N/A") {
        [System.Windows.Forms.MessageBox]::Show("No valid path available.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    $expanded = Expand-PathString $path
    # If it's an exe or file, select it in Explorer
    if ($expanded -and (Test-Path $expanded -PathType Leaf)) {
        Start-Process "explorer.exe" -ArgumentList "/select,`"$expanded`""
        return
    }

    # Try to extract an exe from a commandline-like string
    $exe = Get-ExeCandidateFromString $expanded
    if ($exe) {
        if (Test-Path $exe) {
            Start-Process "explorer.exe" -ArgumentList "/select,`"$exe`""
            return
        }
    }

    # If it's a directory, open it; otherwise try parent directory
    if ($expanded -and (Test-Path $expanded -PathType Container)) {
        Start-Process "explorer.exe" -ArgumentList "`"$expanded`""
        return
    }
    $dir = $null
    if ($expanded) { $dir = Split-Path $expanded -Parent }
    if ($dir -and (Test-Path $dir)) {
        Start-Process "explorer.exe" -ArgumentList "`"$dir`""
        return
    }
    [System.Windows.Forms.MessageBox]::Show("Path not found or inaccessible.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
}

function Launch-AVProgram {
    param($path, $name)
    
    # Special handling for Windows Defender
    if ($name -like "*Windows Defender*" -or $name -like "*Windows Security*") {
        Start-Process "windowsdefender:"
        return
    }
    
    # Known AV UI executables to look for
    $avUIExecutables = @{
        'Avast' = @('AvastUI.exe', 'ashDisp.exe', 'avastui.exe')
        'AVG' = @('AVGUI.exe', 'avgui.exe')
        'Avira' = @('Avira.ServiceHost.exe', 'avgnt.exe', 'avguard.exe')
        'Kaspersky' = @('avpui.exe', 'avp.exe')
        'Bitdefender' = @('bdagent.exe', 'bdservicehost.exe')
        'ESET' = @('egui.exe', 'ecls.exe')
        'Norton' = @('NortonSecurity.exe', 'uiStub.exe')
        'McAfee' = @('McUICnt.exe', 'ModuleCoreService.exe')
        'Malwarebytes' = @('mbam.exe', 'mbamtray.exe')
        'Sophos' = @('SophosUI.exe', 'SAVAdminService.exe')
        'Panda' = @('PSKTRAY.exe', 'PavFnSvr.exe')
        'Webroot' = @('WRSA.exe', 'WRTray.exe')
    }
    
    # Try to launch the executable from path
    if ($path -and $path -ne "N/A") {
        try {
            # Extract base directory from path (expand env vars first)
            $baseDir = $null
            $expanded = Expand-PathString $path

            if (Test-Path $expanded -PathType Container) {
                $baseDir = $expanded
            }
            elseif (Test-Path $expanded -PathType Leaf) {
                $baseDir = Split-Path $expanded -Parent
            }
            else {
                $exePath = Get-ExeCandidateFromString $expanded
                if (Test-Path $exePath) {
                    $baseDir = Split-Path $exePath -Parent
                }
            }
            
            # If we have a base directory, look for known UI executables
            if ($baseDir) {
                # First try known UI executables for this specific AV
                foreach ($avName in $avUIExecutables.Keys) {
                    if ($name -like "*$avName*") {
                        foreach ($uiExe in $avUIExecutables[$avName]) {
                            $fullPath = Join-Path $baseDir $uiExe
                            if (Test-Path $fullPath) {
                                Start-Process $fullPath
                                return
                            }
                            # Also check parent and common subdirectories
                            $searchDirs = @(
                                $baseDir,
                                (Split-Path $baseDir -Parent),
                                (Join-Path $baseDir "bin"),
                                (Join-Path $baseDir "UI")
                            )
                            foreach ($dir in $searchDirs) {
                                if ($dir -and (Test-Path $dir)) {
                                    $found = Get-ChildItem -Path $dir -Filter $uiExe -Recurse -Depth 2 -ErrorAction SilentlyContinue | Select-Object -First 1
                                    if ($found) {
                                        Start-Process $found.FullName
                                        return
                                    }
                                }
                            }
                        }
                        break
                    }
                }
            }
            
            # Last resort: if path is a valid executable, try to launch it
            if (Test-Path $path -PathType Leaf) {
                Start-Process $path
                return
            }
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("Failed to launch $name. Error: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            return
        }
    }
    
    [System.Windows.Forms.MessageBox]::Show("Could not launch $name. No UI executable found.`n`nPath checked: $path", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
}

# Create GUI
$form = New-Object System.Windows.Forms.Form
$form.Text = "Antivirus Searcher"
$form.Size = New-Object System.Drawing.Size(1000, 600)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(26, 35, 50)

# Status label
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Location = New-Object System.Drawing.Point(10, 10)
$statusLabel.Size = New-Object System.Drawing.Size(960, 25)
$statusLabel.Text = "Scanning for antivirus software..."
$statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
$statusLabel.BackColor = [System.Drawing.Color]::Transparent
$form.Controls.Add($statusLabel)

# DataGridView
$dataGrid = New-Object System.Windows.Forms.DataGridView
$dataGrid.Location = New-Object System.Drawing.Point(10, 45)
$dataGrid.Size = New-Object System.Drawing.Size(960, 445)
$dataGrid.AllowUserToAddRows = $false
$dataGrid.AllowUserToDeleteRows = $false
$dataGrid.ReadOnly = $true
$dataGrid.SelectionMode = [System.Windows.Forms.DataGridViewSelectionMode]::FullRowSelect
$dataGrid.MultiSelect = $false
$dataGrid.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::Fill
$dataGrid.BackgroundColor = [System.Drawing.Color]::FromArgb(36, 52, 71)
$dataGrid.BorderStyle = [System.Windows.Forms.BorderStyle]::None
$dataGrid.GridColor = [System.Drawing.Color]::FromArgb(70, 95, 120)
$dataGrid.DefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(36, 52, 71)
$dataGrid.DefaultCellStyle.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
$dataGrid.DefaultCellStyle.SelectionBackColor = [System.Drawing.Color]::FromArgb(64, 96, 128)
$dataGrid.DefaultCellStyle.SelectionForeColor = [System.Drawing.Color]::White
$dataGrid.DefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$dataGrid.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(45, 65, 87)
$dataGrid.ColumnHeadersDefaultCellStyle.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
$dataGrid.ColumnHeadersDefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$dataGrid.EnableHeadersVisualStyles = $false
$dataGrid.RowHeadersVisible = $false
$dataGrid.AllowUserToResizeRows = $false
$dataGrid.RowHeadersBorderStyle = [System.Windows.Forms.DataGridViewHeaderBorderStyle]::None
$dataGrid.ColumnHeadersBorderStyle = [System.Windows.Forms.DataGridViewHeaderBorderStyle]::None
$dataGrid.CellBorderStyle = [System.Windows.Forms.DataGridViewCellBorderStyle]::None
$dataGrid.AdvancedColumnHeadersBorderStyle.Left   = [System.Windows.Forms.DataGridViewAdvancedCellBorderStyle]::None
$dataGrid.AdvancedColumnHeadersBorderStyle.Right  = [System.Windows.Forms.DataGridViewAdvancedCellBorderStyle]::None
$dataGrid.AdvancedColumnHeadersBorderStyle.Top    = [System.Windows.Forms.DataGridViewAdvancedCellBorderStyle]::None
$dataGrid.AdvancedColumnHeadersBorderStyle.Bottom = [System.Windows.Forms.DataGridViewAdvancedCellBorderStyle]::None

# Reduce flicker and draw crisp custom grid lines via CellPainting
$doubleBufferProp = $dataGrid.GetType().GetProperty('DoubleBuffered', [System.Reflection.BindingFlags] 'NonPublic, Instance')
if ($doubleBufferProp) { $doubleBufferProp.SetValue($dataGrid, $true, $null) }

$gridLineColor = [System.Drawing.Color]::FromArgb(70, 95, 120)
$headerLineColor = [System.Drawing.Color]::FromArgb(58, 79, 103)
$dataGrid.Add_CellPainting({
    param($s, $e)
    # Paint all cells (including headers) and draw our own subtle dividers
    if ($e.RowIndex -ge 0 -and $e.ColumnIndex -ge 0) {
        $e.Handled = $true
        $e.PaintBackground($e.CellBounds, $true)
        $e.PaintContent($e.CellBounds)
        $pen = New-Object System.Drawing.Pen($gridLineColor)
        # Bottom horizontal line
        $e.Graphics.DrawLine($pen, $e.CellBounds.Left, $e.CellBounds.Bottom - 1, $e.CellBounds.Right, $e.CellBounds.Bottom - 1)
        # Right vertical line
        $e.Graphics.DrawLine($pen, $e.CellBounds.Right - 1, $e.CellBounds.Top, $e.CellBounds.Right - 1, $e.CellBounds.Bottom)
        $pen.Dispose()
    }
    elseif ($e.RowIndex -eq -1 -and $e.ColumnIndex -ge 0) {
        # Column header cell
        $e.Handled = $true
        $e.PaintBackground($e.CellBounds, $true)
        $e.PaintContent($e.CellBounds)
        $penH = New-Object System.Drawing.Pen($headerLineColor)
        # Bottom divider under the header + right separator
        $e.Graphics.DrawLine($penH, $e.CellBounds.Left, $e.CellBounds.Bottom - 1, $e.CellBounds.Right, $e.CellBounds.Bottom - 1)
        $e.Graphics.DrawLine($penH, $e.CellBounds.Right - 1, $e.CellBounds.Top, $e.CellBounds.Right - 1, $e.CellBounds.Bottom)
        $penH.Dispose()
    }
})

# Add columns
$dataGrid.Columns.Add("Name", "Antivirus Name") | Out-Null
$dataGrid.Columns.Add("Status", "Protection Status") | Out-Null
$dataGrid.Columns.Add("Source", "Detected By") | Out-Null
$dataGrid.Columns.Add("Path", "Path") | Out-Null

$dataGrid.Columns[0].Width = 250
$dataGrid.Columns[1].Width = 180
$dataGrid.Columns[2].Width = 200
$dataGrid.Columns[3].Width = 410

$form.Controls.Add($dataGrid)

# Helper to create simple buttons (no custom painting)
function Create-StyledButton {
    param($text, $x, $y)
    
    $btn = New-Object System.Windows.Forms.Button
    $btn.Location = New-Object System.Drawing.Point($x, $y)
    $btn.Size = New-Object System.Drawing.Size(150, 38)
    $btn.Text = $text
    # Minimal styling for dark theme without custom painting
    $btn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btn.BackColor = [System.Drawing.Color]::FromArgb(58, 79, 103)
    $btn.ForeColor = [System.Drawing.Color]::White
    $btn.FlatAppearance.BorderSize = 1
    $btn.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(80, 110, 140)
    $btn.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(74, 98, 127)
    $btn.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::FromArgb(54, 74, 96)
    $btn.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Regular)
    $btn.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btn.UseVisualStyleBackColor = $false
    
    return $btn
}

# Buttons
$btnOpenLocation = Create-StyledButton "Open Location" 10 502
$btnOpenLocation.Add_Click({
    if ($dataGrid.SelectedRows.Count -gt 0) {
        $selectedRow = $dataGrid.SelectedRows[0]
        $path = $selectedRow.Cells[3].Value
        Open-AVLocation -path $path
    }
})
$form.Controls.Add($btnOpenLocation)

$btnLaunch = Create-StyledButton "Launch Program" 170 502
$btnLaunch.Add_Click({
    if ($dataGrid.SelectedRows.Count -gt 0) {
        $selectedRow = $dataGrid.SelectedRows[0]
        $path = $selectedRow.Cells[3].Value
        $name = $selectedRow.Cells[0].Value
        Launch-AVProgram -path $path -name $name
    }
})
$form.Controls.Add($btnLaunch)

$btnHelp = Create-StyledButton "Select AV..." 330 502
$btnHelp.Enabled = $false
$btnHelp.Add_Click({
    if ($dataGrid.SelectedRows.Count -gt 0) {
        $selectedRow = $dataGrid.SelectedRows[0]
        $name = $selectedRow.Cells[0].Value
        
        # Check if it's Windows Defender
        if ($name -like '*Windows Defender*' -or $name -like '*Windows Security*') {
            # Open YouTube tutorial for Defender exclusions
            Start-Process "https://www.youtube.com/watch?v=UbtuQwgNfp0"
        } else {
            # Open Google search for uninstalling the specific AV
            $searchQuery = "How to uninstall $name"
            $encodedQuery = [System.Uri]::EscapeDataString($searchQuery)
            Start-Process "https://www.google.com/search?q=$encodedQuery"
        }
    }
})
$form.Controls.Add($btnHelp)

# Update button text when selection changes
$dataGrid.Add_SelectionChanged({
    if ($dataGrid.SelectedRows.Count -gt 0) {
        $selectedRow = $dataGrid.SelectedRows[0]
        $name = $selectedRow.Cells[0].Value
        
        if ($name -like '*Windows Defender*' -or $name -like '*Windows Security*') {
            $btnHelp.Text = "Exclusion Guide"
        } else {
            # Truncate long AV names for button
            $shortName = if ($name.Length -gt 15) { $name.Substring(0, 15) + "..." } else { $name }
            $btnHelp.Text = "Uninstall $shortName"
        }
        $btnHelp.Enabled = $true
    } else {
        $btnHelp.Text = "Select AV..."
        $btnHelp.Enabled = $false
    }
})

$btnRefresh = Create-StyledButton "Refresh" 820 502
$btnRefresh.Add_Click({
    Refresh-AVList
})
$form.Controls.Add($btnRefresh)

function Refresh-AVList {
    $dataGrid.Rows.Clear()
    $statusLabel.Text = "Scanning for antivirus software..."
    $form.Refresh()
    
    # Collect all AV data from SecurityCenter2 only (with WMIC fallback inside)
    $avList = Get-AVFromSecurityCenter
    $totalCount = @($avList).Count
    
    # Post-process Windows Defender status using Defender registry (authoritative)
    $defenderMode = Get-DefenderStatus
    foreach ($av in $avList) {
        if ((($av.Name -like '*Windows Defender*') -or ($av.Name -like '*Windows Security*')) -and $defenderMode -ne $null) {
            $av.Enabled = $defenderMode
            if (-not ($av.PSObject.Properties.Name -contains 'StatusSource')) {
                Add-Member -InputObject $av -NotePropertyName StatusSource -NotePropertyValue $null -ErrorAction SilentlyContinue
            }
            $av.StatusSource = 'DefenderModule'
        }
    }
    
    # Populate grid (engines only)
    foreach ($av in $avList) {
        $statusText = if ($av.Enabled -eq $true) { "[ACTIVE]" } 
                      elseif ($av.Enabled -eq "Passive") { "[PASSIVE]" }
                      elseif ($av.Enabled -eq $false) { "[DISABLED]" } 
                      else { "[UNKNOWN]" }
        $sourcesText = if ($av.StatusSource) { $av.StatusSource } else { $av.Source }
        $displayPath = if ($av.Path) { Expand-PathString $av.Path } else { $av.Path }
        $dataGrid.Rows.Add($av.Name, $statusText, $sourcesText, $displayPath) | Out-Null
    }
    
    # Count active vs passive AVs for status summary (robust to string/bool values)
    $activeItems = @($avList | Where-Object { ($_.Enabled -is [bool] -and $_.Enabled) -or (([string]$_.Enabled).ToLower() -eq 'active' -or ([string]$_.Enabled).ToLower() -eq 'true') })
    $passiveItems = @($avList | Where-Object { ([string]$_.Enabled).ToLower() -eq 'passive' })
    $disabledItems = @($avList | Where-Object { ($_.Enabled -is [bool] -and -not $_.Enabled) -or (([string]$_.Enabled).ToLower() -eq 'false' -or ([string]$_.Enabled).ToLower() -eq 'disabled') })
        $activeCount = $activeItems.Count
        $passiveCount = $passiveItems.Count
        $disabledCount = $disabledItems.Count
    
        if ($activeCount -gt 0) {
        # Prefer a third-party AV as the displayed primary if present, otherwise Defender
        $primaryAV = (
          ($activeItems | Where-Object { $_.Name -ne 'Windows Defender' } | Select-Object -First 1).Name
        )
        if (-not $primaryAV) {
          $primaryAV = ($activeItems | Where-Object { $_.Name -eq 'Windows Defender' } | Select-Object -First 1).Name
        }
        $statusLabel.Text = "ACTIVE PROTECTION: $primaryAV is actively protecting - $totalCount total product(s) found"
    } elseif ($passiveCount -gt 0) {
        $statusLabel.Text = "WARNING: Only passive protection detected - $totalCount total product(s) found"
    } else {
        $statusLabel.Text = "ERROR: No active antivirus protection detected - $totalCount total product(s) found"
    }
}

# Initial scan
$form.Add_Shown({
    Refresh-AVList
})

# Show form
[void]$form.ShowDialog()
