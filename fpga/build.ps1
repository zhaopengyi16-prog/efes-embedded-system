param(
    [switch]$Simulate,
    [string]$QuartusRoot = $env:QUARTUS_ROOTDIR,
    [string]$ModelSimRoot = $env:MODELSIM_ROOT
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($QuartusRoot)) {
    $QuartusRoot = 'D:\intelFPGA_lite\18.1\quartus'
}
if ([string]::IsNullOrWhiteSpace($ModelSimRoot)) {
    $ModelSimRoot = Join-Path (Split-Path $QuartusRoot -Parent) 'modelsim_ase\win32aloem'
}

$buildDirectory = Join-Path $PSScriptRoot 'build'
New-Item -ItemType Directory -Path $buildDirectory -Force | Out-Null

if ($Simulate) {
    $tool = Join-Path $ModelSimRoot 'vsim.exe'
    $workingDirectory = Join-Path $buildDirectory 'sim'
    $simulationScript = Join-Path $PSScriptRoot 'sim\run.do'
    $arguments = @('-c', '-do', ('"{0}"' -f $simulationScript))
    $logName = 'modelsim'
    Write-Host 'Simulating the FPGA starter with ModelSim.'
}
else {
    $tool = Join-Path $QuartusRoot 'bin64\quartus_sh.exe'
    $workingDirectory = Join-Path $PSScriptRoot 'quartus'
    $arguments = @('--flow', 'compile', 'efes_fpga')
    $logName = 'quartus'
    Write-Host 'Compiling the DE1-SoC FPGA starter with Quartus.'
}

if (-not (Test-Path -LiteralPath $tool -PathType Leaf)) {
    throw "Tool not found: $tool. Set QUARTUS_ROOTDIR/MODELSIM_ROOT or pass the corresponding parameter."
}

New-Item -ItemType Directory -Path $workingDirectory -Force | Out-Null
$standardOutput = Join-Path $buildDirectory ($logName + '.stdout.log')
$standardError = Join-Path $buildDirectory ($logName + '.stderr.log')
$process = Start-Process -FilePath $tool -ArgumentList $arguments `
    -WorkingDirectory $workingDirectory -WindowStyle Hidden -Wait -PassThru `
    -RedirectStandardOutput $standardOutput -RedirectStandardError $standardError

Get-Content -LiteralPath $standardOutput
if ((Get-Item -LiteralPath $standardError).Length -gt 0) {
    Get-Content -LiteralPath $standardError
}
if ($process.ExitCode -ne 0) {
    Write-Error "$logName failed with exit code $($process.ExitCode)." -ErrorAction Continue
    exit $process.ExitCode
}

if ($Simulate) {
    if (-not (Select-String -LiteralPath $standardOutput -SimpleMatch 'PASS: FPGA starter simulation' -Quiet)) {
        throw 'The simulator exited without the testbench pass result.'
    }
    Write-Host "Simulation passed. Waveform: $workingDirectory\efes_top_tb.vcd"
}
else {
    $programmingFile = Join-Path $workingDirectory 'output_files\efes_fpga.sof'
    if (-not (Test-Path -LiteralPath $programmingFile -PathType Leaf)) {
        throw 'Quartus exited successfully, but the SOF programming file was not produced.'
    }
    Write-Host "Build complete. Programming file: $programmingFile"
}
exit 0
