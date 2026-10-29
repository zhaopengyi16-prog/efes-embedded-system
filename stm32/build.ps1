param(
    [switch]$Rebuild,
    [string]$KeilRoot = $env:KEIL_ROOT
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($KeilRoot)) {
    $KeilRoot = 'D:\Keil_v5'
}

$uv = Join-Path $KeilRoot 'UV4\UV4.exe'
$project = Join-Path $PSScriptRoot 'EEFS.uvprojx'
$buildDirectory = Join-Path $PSScriptRoot 'build'
$buildLog = Join-Path $buildDirectory 'keil-build.log'

if (-not (Test-Path -LiteralPath $uv -PathType Leaf)) {
    throw 'Keil was not found. Set KEIL_ROOT or pass -KeilRoot with its install directory.'
}
if (-not (Test-Path -LiteralPath $project -PathType Leaf)) {
    throw "Project not found: $project"
}

New-Item -ItemType Directory -Path $buildDirectory -Force | Out-Null
$mode = if ($Rebuild) { '-r' } else { '-b' }
$arguments = @(
    $mode,
    ('"{0}"' -f $project),
    '-t"App"',
    '-j0',
    '-o',
    ('"{0}"' -f $buildLog)
)

Write-Host "Building STM32G431RBT6 with $uv"
$process = Start-Process -FilePath $uv -ArgumentList $arguments `
    -WorkingDirectory $PSScriptRoot -WindowStyle Hidden -Wait -PassThru

if (Test-Path -LiteralPath $buildLog) {
    Get-Content -LiteralPath $buildLog
}
else {
    throw 'Keil did not create the build log. Check the tool installation and project.'
}

# Keil returns 1 for warnings only. VS Code should report that as a successful build.
if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 1) {
    if (-not (Test-Path -LiteralPath (Join-Path $buildDirectory 'EEFS.axf'))) {
        throw 'Keil reported success, but the executable was not produced.'
    }
    Write-Host "Build complete. Output directory: $buildDirectory"
    exit 0
}

Write-Error "Keil build failed with exit code $($process.ExitCode)." -ErrorAction Continue
exit $process.ExitCode
