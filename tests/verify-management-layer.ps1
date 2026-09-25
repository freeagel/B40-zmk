param(
    [Parameter(Mandatory = $true)]
    [string]$DtsPath
)

$ErrorActionPreference = 'Stop'

$resolved = (Resolve-Path -LiteralPath $DtsPath).Path
$dts = [System.IO.File]::ReadAllText($resolved)
$layerMatch = [regex]::Match(
    $dts,
    '(?ms)^\s*management_layer\s*\{.*?bindings\s*=\s*<(?<bindings>.*?)>;.*?^\s*\};'
)
if (-not $layerMatch.Success) {
    throw 'Management layer was not found in compiled Devicetree.'
}

$bindingsText = $layerMatch.Groups['bindings'].Value
$tokenPattern = '&bt\s+(?<btCommand>0x[0-9a-fA-F]+)\s+(?<btProfile>0x[0-9a-fA-F]+)|&kp\s+(?<kp>0x[0-9a-fA-F]+)|&(?<zeroCell>studio_unlock|soft_off|sys_reset|trans)'
$unparsed = [regex]::Replace($bindingsText, $tokenPattern, '')
if (-not [string]::IsNullOrWhiteSpace($unparsed)) {
    throw "Unrecognized Management binding text: '$($unparsed.Trim())'"
}
$actual = @(
    [regex]::Matches($bindingsText, $tokenPattern) | ForEach-Object {
        if ($_.Groups['btCommand'].Success) {
            "bt:$($_.Groups['btCommand'].Value.ToLowerInvariant()):$($_.Groups['btProfile'].Value.ToLowerInvariant())"
        } elseif ($_.Groups['kp'].Success) {
            "kp:$($_.Groups['kp'].Value.ToLowerInvariant())"
        } else {
            $_.Groups['zeroCell'].Value
        }
    }
)

$expected = @(
    'trans', 'trans', 'bt:0x3:0x0', 'bt:0x3:0x1', 'bt:0x3:0x2', 'bt:0x3:0x3', 'bt:0x3:0x4', 'studio_unlock', 'trans', 'trans',
    'kp:0x7003a', 'kp:0x7003b', 'kp:0x7003c', 'kp:0x7003d', 'kp:0x7003e', 'kp:0x7003f', 'kp:0x70040', 'kp:0x70041', 'kp:0x70042', 'kp:0x70043',
    'kp:0x70044', 'kp:0x70045', 'kp:0x7004b', 'kp:0x7004e', 'kp:0x7004a', 'kp:0x7004d', 'kp:0xc00ea', 'kp:0xc00e9', 'kp:0xc00e2', 'kp:0xc00cd',
    'kp:0xc00b6', 'kp:0xc00b5', 'kp:0xc0070', 'kp:0xc006f', 'bt:0x0:0x0', 'soft_off', 'bt:0x4:0x0', 'sys_reset', 'kp:0x7007a', 'kp:0x70079'
)

if ($actual.Count -ne 40) {
    throw "Expected 40 compiled Management bindings, found $($actual.Count)."
}

$differences = @()
for ($index = 0; $index -lt $expected.Count; $index++) {
    if ($actual[$index] -ne $expected[$index]) {
        $row = [math]::Floor($index / 10) + 1
        $column = ($index % 10) + 1
        $differences += "row $row column ${column}: expected '$($expected[$index])', found '$($actual[$index])'"
    }
}
if ($differences.Count -gt 0) {
    throw "Compiled Management layout differs:`n$($differences -join "`n")"
}

Write-Host 'PASS: compiled Management layer has all 40 expected bindings.'
