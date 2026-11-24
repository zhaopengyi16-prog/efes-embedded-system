param(
    [switch]$Simulate,
    [switch]$Program,
    [ValidateSet('DE1SoC', 'CYC5000')]
    [string]$Board = 'DE1SoC',
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
    if ($Board -eq 'CYC5000') {
        $projectDirectory = 'quartus_cyc5000'
        $projectName = 'efes_cyc5000'
    }
    else {
        $projectDirectory = 'quartus'
        $projectName = 'efes_fpga'
    }
    $workingDirectory = Join-Path $PSScriptRoot $projectDirectory
    if ($Program) {
        # Program the first JTAG cable; the CYC5000 chain has one device.
        $tool = Join-Path $QuartusRoot 'bin64\quartus_pgm.exe'
        $arguments = @('-c', '1', '-m', 'JTAG', '-o', ('"p;output_files\{0}.sof"' -f $projectName))
        $logName = 'program'
        Write-Host "Programming $Board with $projectName.sof."
    }
    else {
        $tool = Join-Path $QuartusRoot 'bin64\quartus_sh.exe'
        $arguments = @('--flow', 'compile', $projectName)
        $logName = 'quartus'
        Write-Host "Compiling the $Board FPGA project with Quartus."
    }
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
elseif ($Program) {
    Write-Host 'Programming complete.'
}
else {
    $programmingFile = Join-Path $workingDirectory ('output_files\{0}.sof' -f $projectName)
    if (-not (Test-Path -LiteralPath $programmingFile -PathType Leaf)) {
        throw 'Quartus exited successfully, but the SOF programming file was not produced.'
    }
    Write-Host "Build complete. Programming file: $programmingFile"
}
exit 0
