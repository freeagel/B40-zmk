param(
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\docs\b40-layer-map.svg')
)

$ErrorActionPreference = 'Stop'

$json = @'
[
  {
    "name": "Base · 기본",
    "hint": "기본 입력 — 보라색 키를 누르는 동안 해당 레이어 활성화",
    "keys": [
      "Q","W","E","R","T","Y","U","I","O","P",
      "A","S","D","F","G","H","J","K","L","Bksp",
      "Z / Shift","X","C","V","B","N","M",",",".","RShift",
      "LShift","LCtrl","LAlt","NumShift","Number","Space","Nav","-","'","Enter"
    ]
  },
  {
    "name": "Number · 숫자",
    "hint": "Base의 Number 키를 누른 상태",
    "keys": [
      "1","2","3","4","5","6","7","8","9","0",
      "Tab","·","·","·","·","·","[","]","\\","Del",
      "·","·","·","·","·","·","`","-","=","/",
      "LShift","·","·","·","·","·","·","·",";","·"
    ]
  },
  {
    "name": "Number Shift · 기호",
    "hint": "Base의 NumShift 키를 누른 상태 — 숫자열 Shift 기호",
    "keys": [
      "!","@","#","$","%","^","&","*","(",")",
      "Tab","·","·","·","·","·","{","}","|","Del",
      "·","·","·","·","·","·","~","_","+","?",
      "LShift","·","·","·","·","·","·","·","\"","·"
    ]
  },
  {
    "name": "Nav · 이동/스크롤",
    "hint": "Base의 Nav 키를 누른 상태",
    "keys": [
      "Esc","Home","↑","End","·","·","Left Click","Mouse ↑","Right Click","Alt+Tab",
      "Tab","←","↓","→","·","Android Home","Mouse ←","Mouse ↓","Mouse →","Del",
      "·","·","·","·","Android Back","Android Forward","·","Home","↑","End",
      "GUI","·","·","·","Scroll Up","Scroll Down","·","←","↓","→"
    ]
  },
  {
    "name": "Management · 관리",
    "hint": "Base에서 Q + P를 함께 누른 상태",
    "keys": [
      "·","·","BT P0","BT P1","BT P2","BT P3","BT P4","Studio Unlock","·","·",
      "F1","F2","F3","F4","F5","F6","F7","F8","F9","F10",
      "F11","F12","PgUp","PgDn","Home","End","Vol-","Vol+","Mute","Play/Pause",
      "Prev","Next","Bright-","Bright+","BT Clear","Sleep","BT Clear All","Reset","Undo","Redo"
    ]
  }
]
'@

$layers = $json | ConvertFrom-Json
$expectedLayers = 5
$expectedKeys = 40
if ($layers.Count -ne $expectedLayers) {
    throw "Expected $expectedLayers layers, found $($layers.Count)"
}
foreach ($layer in $layers) {
    if ($layer.keys.Count -ne $expectedKeys) {
        throw "Layer '$($layer.name)' has $($layer.keys.Count) keys, expected $expectedKeys"
    }
}

function Escape-Xml([string]$Value) {
    return [System.Security.SecurityElement]::Escape($Value)
}

function Get-KeyClass([string]$Label) {
    if ($Label -eq '·') { return 'transparent' }
    if ($Label -in @('NumShift', 'Number', 'Nav')) { return 'layer' }
    if ($Label -in @('↑', '↓', '←', '→', 'Scroll Up', 'Scroll Down') -or $Label -match '^(Mouse |Left Click$|Right Click$)') { return 'nav' }
    if ($Label -match '^(BT |Studio |Android |Alt\+Tab$|Esc$|Del$|GUI$|Vol|Mute$|Play/|Prev$|Next$|Bright|Sleep$|Reset$|Menu$|Undo$|Redo$)') { return 'system' }
    return 'normal'
}

function Add-KeyText([System.Text.StringBuilder]$Builder, [string]$Label, [double]$CenterX, [double]$CenterY) {
    $escaped = Escape-Xml $Label
    if ($Label -eq 'Scroll Up') {
        [void]$Builder.AppendLine("<text class='key-label small' x='$CenterX' y='$($CenterY - 7)'><tspan x='$CenterX'>Scroll</tspan><tspan x='$CenterX' dy='18'>Up</tspan></text>")
    } elseif ($Label -eq 'Scroll Down') {
        [void]$Builder.AppendLine("<text class='key-label small' x='$CenterX' y='$($CenterY - 7)'><tspan x='$CenterX'>Scroll</tspan><tspan x='$CenterX' dy='18'>Down</tspan></text>")
    } elseif ($Label -eq 'Studio Unlock') {
        [void]$Builder.AppendLine("<text class='key-label tiny' x='$CenterX' y='$($CenterY - 7)'><tspan x='$CenterX'>Studio</tspan><tspan x='$CenterX' dy='17'>Unlock</tspan></text>")
    } elseif ($Label -match '^(Left|Right|Mouse|Android) ') {
        $parts = $Label.Split(' ', 2)
        $first = Escape-Xml $parts[0]
        $second = Escape-Xml $parts[1]
        [void]$Builder.AppendLine("<text class='key-label tiny' x='$CenterX' y='$($CenterY - 7)'><tspan x='$CenterX'>$first</tspan><tspan x='$CenterX' dy='17'>$second</tspan></text>")
    } else {
        $sizeClass = if ($Label.Length -gt 7) { 'small' } else { '' }
        [void]$Builder.AppendLine("<text class='key-label $sizeClass' x='$CenterX' y='$($CenterY + 6)'>$escaped</text>")
    }
}

$width = 2400
$height = 1600
$panelWidth = 1100
$panelHeight = 415
$keyWidth = 97
$keyHeight = 68
$gap = 8
$positions = @(
    @{ x = 90;   y = 120 },
    @{ x = 1210; y = 120 },
    @{ x = 90;   y = 570 },
    @{ x = 1210; y = 570 },
    @{ x = 650;  y = 1020 }
)

$svg = [System.Text.StringBuilder]::new()
[void]$svg.AppendLine("<svg xmlns='http://www.w3.org/2000/svg' width='$width' height='$height' viewBox='0 0 $width $height' role='img' aria-labelledby='title desc'>")
[void]$svg.AppendLine(@'
<title id="title">B40 ZMK 4×10 레이어 맵</title>
<desc id="desc">Base, Number, Number Shift, Nav, Management 다섯 레이어의 정확한 4행 10열 키 배치</desc>
<style>
  :root { color-scheme: dark; }
  .bg { fill: #0d1118; }
  .panel { fill: #141b25; stroke: #2d3a4c; stroke-width: 2; }
  .panel-title { fill: #f2f5fa; font: 700 30px Inter, "Noto Sans KR", "Malgun Gothic", sans-serif; }
  .panel-hint { fill: #91a0b5; font: 400 17px Inter, "Noto Sans KR", "Malgun Gothic", sans-serif; }
  .key { stroke: #48576b; stroke-width: 2; }
  .normal { fill: #222c39; }
  .layer { fill: #6d5dfc; stroke: #a99fff; }
  .nav { fill: #0f7189; stroke: #54c3db; }
  .system { fill: #a85f1d; stroke: #e3a55f; }
  .transparent { fill: #171e28; stroke: #303b49; }
  .key-label { fill: #f4f7fb; text-anchor: middle; font: 600 20px Inter, "Noto Sans KR", "Malgun Gothic", sans-serif; pointer-events: none; }
  .key-label.small { font-size: 16px; }
  .key-label.tiny { font-size: 14px; }
  .transparent + .key-label { fill: #637086; }
  .header { fill: #f6f8fb; font: 800 38px Inter, "Noto Sans KR", "Malgun Gothic", sans-serif; }
  .subheader { fill: #91a0b5; font: 400 18px Inter, "Noto Sans KR", "Malgun Gothic", sans-serif; }
  .legend { fill: #aeb9c9; font: 500 17px Inter, "Noto Sans KR", "Malgun Gothic", sans-serif; }
</style>
<rect class="bg" width="2400" height="1600"/>
<text class="header" x="90" y="58">B40 ZMK · 4×10 Ortholinear Layer Map</text>
<text class="subheader" x="90" y="91">현재 펌웨어 기준 · Scroll 고정 속도 30 / 가속 없음 · 점(·)은 Base 키 동작 통과</text>
'@)

for ($layerIndex = 0; $layerIndex -lt $layers.Count; $layerIndex++) {
    $layer = $layers[$layerIndex]
    $px = [double]$positions[$layerIndex].x
    $py = [double]$positions[$layerIndex].y
    $layerName = Escape-Xml $layer.name
    $layerHint = Escape-Xml $layer.hint
    [void]$svg.AppendLine("<g class='layer-panel' data-layer-index='$layerIndex' data-layer-name='$layerName'>")
    [void]$svg.AppendLine("<rect class='panel' x='$px' y='$py' width='$panelWidth' height='$panelHeight' rx='24'/>")
    [void]$svg.AppendLine("<text class='panel-title' x='$($px + 28)' y='$($py + 42)'>$layerName</text>")
    [void]$svg.AppendLine("<text class='panel-hint' x='$($px + 28)' y='$($py + 69)'>$layerHint</text>")

    for ($index = 0; $index -lt $layer.keys.Count; $index++) {
        $row = [math]::Floor($index / 10)
        $col = $index % 10
        $x = $px + 28 + ($col * ($keyWidth + $gap))
        $y = $py + 92 + ($row * ($keyHeight + $gap))
        $cx = $x + ($keyWidth / 2)
        $cy = $y + ($keyHeight / 2)
        $label = [string]$layer.keys[$index]
        $class = Get-KeyClass $label
        $escapedLabel = Escape-Xml $label
        [void]$svg.AppendLine("<g class='key-group' data-key='true' data-index='$index' data-label='$escapedLabel'>")
        [void]$svg.AppendLine("<rect class='key $class' x='$x' y='$y' width='$keyWidth' height='$keyHeight' rx='12'/>")
        Add-KeyText $svg $label $cx $cy
        [void]$svg.AppendLine('</g>')
    }
    [void]$svg.AppendLine('</g>')
}

[void]$svg.AppendLine(@'
<g transform="translate(650 1492)">
  <rect class="key layer" x="0" y="0" width="26" height="26" rx="6"/><text class="legend" x="38" y="20">레이어 키</text>
  <rect class="key nav" x="168" y="0" width="26" height="26" rx="6"/><text class="legend" x="206" y="20">이동·스크롤</text>
  <rect class="key system" x="354" y="0" width="26" height="26" rx="6"/><text class="legend" x="392" y="20">시스템·Bluetooth</text>
  <rect class="key transparent" x="590" y="0" width="26" height="26" rx="6"/><text class="legend" x="628" y="20">Base 통과</text>
</g>
</svg>
'@)

$resolved = [System.IO.Path]::GetFullPath($OutputPath)
$directory = Split-Path -Parent $resolved
[System.IO.Directory]::CreateDirectory($directory) | Out-Null
[System.IO.File]::WriteAllText($resolved, $svg.ToString(), [System.Text.UTF8Encoding]::new($false))
Write-Host "Generated: $resolved"
