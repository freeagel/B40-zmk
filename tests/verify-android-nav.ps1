param(
    [Parameter(Mandatory = $true)]
    [string]$DtsPath
)

$ErrorActionPreference = 'Stop'

function Get-NodeBody([string]$Dts, [string]$NodeName) {
    $match = [regex]::Match(
        $Dts,
        "(?ms)^\s*${NodeName}:?\s*[^\{]*\{(?<body>.*?)^\s*\};"
    )
    if (-not $match.Success) {
        throw "Node '$NodeName' was not found in compiled Devicetree."
    }
    return $match.Groups['body'].Value
}

function Convert-DtsInteger([string]$Value) {
    if ($Value.StartsWith('0x')) {
        return [Convert]::ToInt32($Value.Substring(2), 16)
    }
    return [Convert]::ToInt32($Value, 10)
}

$resolved = (Resolve-Path -LiteralPath $DtsPath).Path
$dts = [System.IO.File]::ReadAllText($resolved)
$failures = @()
$navBody = Get-NodeBody $dts 'nav_layer'
$bindingsMatch = [regex]::Match($navBody, '(?ms)bindings\s*=\s*<(?<bindings>.*?)>;')
if (-not $bindingsMatch.Success) {
    throw 'Nav bindings were not found in compiled Devicetree.'
}

$actual = @(
    [regex]::Matches(
        $bindingsMatch.Groups['bindings'].Value,
        '&(?<behavior>[A-Za-z0-9_]+)(?:\s+(?<parameter>0x[0-9a-fA-F]+))?'
    ) | ForEach-Object {
        $behavior = $_.Groups['behavior'].Value
        $parameter = $_.Groups['parameter'].Value.ToLowerInvariant()
        if ($parameter) { "${behavior}:${parameter}" } else { $behavior }
    }
)

$expected = @(
    'kp:0x70029', 'kp:0x7004a', 'kp:0x70052', 'kp:0x7004d', 'trans',       'trans',        'mkp:0x1',       'mmv:0xfda8',     'mkp:0x2',       'kp:0x407002b',
    'kp:0x7002b', 'kp:0x70050', 'kp:0x70051', 'kp:0x7004f', 'trans',       'kp:0x807000b',  'mmv:0xfda80000', 'mmv:0x258',      'mmv:0x2580000',  'kp:0x7004c',
    'trans',      'trans',      'trans',      'trans',      'kp:0x700f1',  'kp:0x700f2',   'trans',           'kp:0x7004a',     'kp:0x70052',     'kp:0x7004d',
    'kp:0x700e3', 'trans',      'trans',      'trans',      'msc:0x1e',    'msc:0xffe2',    'trans',           'kp:0x70050',     'kp:0x70051',     'kp:0x7004f'
)

if ($actual.Count -ne 40) {
    throw "Expected 40 compiled Nav bindings, found $($actual.Count)."
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
    $failures += "Compiled Nav layout differs:`n$($differences -join "`n")"
}

$scrollBody = Get-NodeBody $dts 'msc'
$timeMatch = [regex]::Match($scrollBody, 'time-to-max-speed-ms\s*=\s*<\s*(?<value>0x[0-9a-fA-F]+|[0-9]+)\s*>;')
$exponentMatch = [regex]::Match($scrollBody, 'acceleration-exponent\s*=\s*<\s*(?<value>0x[0-9a-fA-F]+|[0-9]+)\s*>;')
if (-not $timeMatch.Success -or (Convert-DtsInteger $timeMatch.Groups['value'].Value) -ne 300) {
    $failures += 'Compiled mouse scroll time-to-max-speed-ms is not 300.'
}
if (-not $exponentMatch.Success -or (Convert-DtsInteger $exponentMatch.Groups['value'].Value) -ne 0) {
    $failures += 'Compiled mouse scroll acceleration-exponent is not 0.'
}

if ($failures.Count -gt 0) {
    throw ($failures -join "`n")
}

Write-Host 'PASS: compiled Android Nav layout has 40 expected bindings.'
Write-Host 'PASS: scroll uses fixed speed with acceleration disabled.'
