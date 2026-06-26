# scwap unified statusline: [SP] + ponytail badge + caveman badge.
$Dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Esc = [char]27
$out = "${Esc}[38;5;110m[SP]${Esc}[0m"
$pony = & powershell -ExecutionPolicy Bypass -File "$Dir\ponytail-statusline.ps1" 2>$null
if ($pony) { $out = "$out  $pony" }
$cave = & powershell -ExecutionPolicy Bypass -File "$Dir\caveman-statusline.ps1" 2>$null
if ($cave) { $out = "$out  $cave" }
[Console]::Write($out)
