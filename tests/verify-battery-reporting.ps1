param(
    [Parameter(Mandatory = $true)]
    [string]$DtsPath,

    [Parameter(Mandatory = $true)]
    [string]$ConfigPath
)

$ErrorActionPreference = 'Stop'

$dts = [System.IO.File]::ReadAllText((Resolve-Path -LiteralPath $DtsPath).Path)
$config = [System.IO.File]::ReadAllText((Resolve-Path -LiteralPath $ConfigPath).Path)
$failures = @()

$chosen = [regex]::Match($dts, '(?ms)^\s*chosen\s*\{(?<body>.*?)^\s*\};')
if (-not $chosen.Success) {
    $failures += 'Compiled Devicetree has no chosen node.'
} elseif ($chosen.Groups['body'].Value -notmatch 'zmk,battery\s*=\s*(?:<\s*)?&vbatt(?:\s*>)?;') {
    $failures += 'Compiled chosen node does not select &vbatt as zmk,battery.'
}

$vbatt = [regex]::Match($dts, '(?ms)^\s*vbatt:\s*vbatt\s*\{(?<body>.*?)^\s*\};')
if (-not $vbatt.Success) {
    $failures += 'Compiled Devicetree has no vbatt node.'
} elseif ($vbatt.Groups['body'].Value -notmatch 'compatible\s*=\s*"zmk,battery-nrf-vddh";') {
    $failures += 'Compiled vbatt node is not the nRF VDDH battery sensor.'
}

if ($dts -match 'compatible\s*=\s*"(?:zmk,battery-)?voltage-divider";') {
    $failures += 'A voltage-divider battery sensor is active in compiled Devicetree.'
}

$kscan = [regex]::Match($dts, '(?ms)^\s*kscan:\s*kscan\s*\{(?<body>.*?)^\s*\};')
if (-not $kscan.Success) {
    $failures += 'Compiled Devicetree has no kscan node.'
} else {
    $p024Uses = [regex]::Matches($kscan.Groups['body'].Value, '<\s*&gpio0\s+0x18\s+0x[0-9a-fA-F]+\s*>').Count
    if ($p024Uses -ne 1) {
        $failures += "Expected matrix column P0.24 exactly once, found $p024Uses uses."
    }
}

$requiredOptions = @(
    'CONFIG_ZMK_BATTERY_REPORTING=y',
    'CONFIG_ZMK_BATTERY_REPORTING_FETCH_MODE_LITHIUM_VOLTAGE=y',
    'CONFIG_ZMK_BATTERY_NRF_VDDH=y',
    'CONFIG_ADC=y',
    'CONFIG_BT_BAS=y'
)

foreach ($option in $requiredOptions) {
    if ($config -notmatch "(?m)^$([regex]::Escape($option))$") {
        $failures += "Missing compiled Kconfig option: $option"
    }
}

if ($failures.Count -gt 0) {
    throw ($failures -join "`n")
}

Write-Host 'PASS: compiled Devicetree selects the nRF VDDH battery sensor.'
Write-Host 'PASS: compiled Kconfig enables voltage-based ZMK battery reporting and BLE BAS.'
Write-Host 'PASS: voltage-divider sensing is absent and matrix column P0.24 is preserved.'
