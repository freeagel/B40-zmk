param(
    [Parameter(Mandatory = $true)]
    [string]$DtsPath
)

$ErrorActionPreference = 'Stop'

function Get-NodeBody([string]$Dts, [string]$NodeName) {
    $match = [regex]::Match(
        $Dts,
        "(?ms)^\s*(?:${NodeName}:\s*)?${NodeName}\s*\{(?<body>.*?)^\s*\};"
    )
    if (-not $match.Success) {
        throw "Node '$NodeName' was not found in compiled Devicetree."
    }
    return $match.Groups['body'].Value
}

function Get-Bindings([string]$NodeBody) {
    $match = [regex]::Match($NodeBody, '(?ms)bindings\s*=\s*<(?<bindings>.*?)>;')
    if (-not $match.Success) {
        throw 'Bindings were not found in compiled Devicetree node.'
    }

    return @(
        [regex]::Matches(
            $match.Groups['bindings'].Value,
            '&(?<behavior>[A-Za-z0-9_]+)(?:\s+(?<parameter1>0x[0-9a-fA-F]+))?(?:\s+(?<parameter2>0x[0-9a-fA-F]+))?'
        ) | ForEach-Object {
            $parts = @($_.Groups['behavior'].Value)
            if ($_.Groups['parameter1'].Success) {
                $parts += $_.Groups['parameter1'].Value.ToLowerInvariant()
            }
            if ($_.Groups['parameter2'].Success) {
                $parts += $_.Groups['parameter2'].Value.ToLowerInvariant()
            }
            $parts -join ':'
        }
    )
}

$dts = [System.IO.File]::ReadAllText((Resolve-Path -LiteralPath $DtsPath).Path)
$failures = @()

try {
    $zShift = Get-NodeBody $dts 'z_shift'
    if ($zShift -notmatch 'compatible\s*=\s*"zmk,behavior-hold-tap";') {
        $failures += 'z_shift is not a hold-tap behavior.'
    }
    if ($zShift -notmatch 'flavor\s*=\s*"hold-preferred";') {
        $failures += 'z_shift is not hold-preferred.'
    }
    if ($zShift -notmatch 'tapping-term-ms\s*=\s*<\s*0x3e8\s*>;') {
        $failures += 'z_shift tapping term is not 1000 ms.'
    }
    if ($zShift -notmatch '(?m)^\s*retro-tap;') {
        $failures += 'z_shift does not enable retro-tap.'
    }
    if ($zShift -notmatch 'bindings\s*=\s*<\s*&kp\s*>\s*,\s*<\s*&kp\s*>;') {
        $failures += 'z_shift does not use key-press behaviors for hold and tap.'
    }
} catch {
    $failures += $_.Exception.Message
}

$base = Get-Bindings (Get-NodeBody $dts 'default_layer')
$number = Get-Bindings (Get-NodeBody $dts 'number_layer')
$numberShift = Get-Bindings (Get-NodeBody $dts 'number_shift_layer')

if ($base.Count -ne 40 -or $number.Count -ne 40 -or $numberShift.Count -ne 40) {
    $failures += "Expected 40 bindings per layer; found Base=$($base.Count), Number=$($number.Count), NumberShift=$($numberShift.Count)."
} else {
    if ($base[20] -ne 'z_shift:0x700e1:0x7001d') {
        $failures += "Base Z position should be Left Shift/Z dual-role; found '$($base[20])'."
    }
    if ($base[38] -ne 'kp:0x70034') {
        $failures += "Base quote position should type apostrophe; found '$($base[38])'."
    }
    if ($number[38] -ne 'kp:0x70033') {
        $failures += "Number quote position should type semicolon; found '$($number[38])'."
    }
    if ($numberShift[38] -ne 'kp:0x2070034') {
        $failures += "NumberShift quote position should type double quote; found '$($numberShift[38])'."
    }
}

if ($failures.Count -gt 0) {
    throw ($failures -join "`n")
}

Write-Host 'PASS: Z is tap-z/hold-Left-Shift with hold-preferred retro-tap behavior.'
Write-Host "PASS: quote position is apostrophe on Base, semicolon on Number, and double quote on NumberShift."
