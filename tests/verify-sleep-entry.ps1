param(
    [Parameter(Mandatory = $true)]
    [string]$DtsPath
)

$ErrorActionPreference = 'Stop'

function Convert-DtsInteger([string]$Value) {
    if ($Value.StartsWith('0x')) {
        return [Convert]::ToInt32($Value.Substring(2), 16)
    }
    return [Convert]::ToInt32($Value, 10)
}

$resolved = (Resolve-Path -LiteralPath $DtsPath).Path
$dts = [System.IO.File]::ReadAllText($resolved)
$failures = @()

if ([regex]::IsMatch($dts, '(?m)^\s*sleep_combo\s*\{')) {
    $failures += 'Legacy H + NumShift + Nav sleep combo is still compiled.'
}

$softOffMatch = [regex]::Match(
    $dts,
    '(?ms)^\s*soft_off:\s*[^\s\{]+\s*\{(?<body>.*?)^\s*\};'
)
if (-not $softOffMatch.Success) {
    $failures += 'Compiled soft-off behavior was not found.'
} else {
    $holdMatch = [regex]::Match(
        $softOffMatch.Groups['body'].Value,
        'hold-time-ms\s*=\s*<\s*(?<value>0x[0-9a-fA-F]+|[0-9]+)\s*>;'
    )
    if (-not $holdMatch.Success -or (Convert-DtsInteger $holdMatch.Groups['value'].Value) -ne 2000) {
        $failures += 'Compiled soft-off hold time is not 2000 ms.'
    }
}

if ($failures.Count -gt 0) {
    throw ($failures -join "`n")
}

Write-Host 'PASS: legacy sleep combo is absent and soft-off hold time is 2000 ms.'
