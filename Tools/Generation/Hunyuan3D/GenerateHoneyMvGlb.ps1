param(
    [Parameter(Mandatory = $false)]
    [string]$InputDir = "Reference\Captures\Honey\TurnaroundSplit",

    [Parameter(Mandatory = $false)]
    [string]$OutputDir = "Assets\Generated\Hunyuan3D\Honey",

    [Parameter(Mandatory = $false)]
    [string]$PythonExe = "python",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Right", "Left")]
    [string]$SideSource = "Right",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Auto", "Hunyuan", "FloodFill", "None")]
    [string]$BackgroundMode = "Auto",

    [Parameter(Mandatory = $false)]
    [int]$FloodfillThreshold = 128,

    [Parameter(Mandatory = $false)]
    [int]$CanvasSize = 1024,

    [Parameter(Mandatory = $false)]
    [double]$SubjectHeightRatio = 0.90,

    [Parameter(Mandatory = $false)]
    [double]$FloorYRatio = 0.96,

    [Parameter(Mandatory = $false)]
    [string]$Device = "cuda",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Front", "FrontLeftBack")]
    [string]$TextureInputMode = "FrontLeftBack",

    [Parameter(Mandatory = $false)]
    [int]$NumInferenceSteps = 50,

    [Parameter(Mandatory = $false)]
    [int]$OctreeResolution = 380,

    [Parameter(Mandatory = $false)]
    [int]$NumChunks = 20000,

    [Parameter(Mandatory = $false)]
    [int]$Seed = 12345,

    [Parameter(Mandatory = $false)]
    [switch]$SkipTexture,

    [Parameter(Mandatory = $false)]
    [switch]$ReuseWhiteGlb,

    [Parameter(Mandatory = $false)]
    [switch]$NoComponentCleanup,

    [Parameter(Mandatory = $false)]
    [switch]$PrepareOnly,

    [Parameter(Mandatory = $false)]
    [switch]$PrintInstallHelp
)

$ErrorActionPreference = "Stop"

function Resolve-RepoRoot {
    return (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\..\..")).Path
}

function Resolve-RepoPath {
    param(
        [string]$PathValue,
        [string]$RepoRoot
    )

    if ([System.IO.Path]::IsPathRooted($PathValue)) {
        return $PathValue
    }

    return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $PathValue))
}

function Write-InstallHelp {
    Write-Host @"
Hunyuan3D Windows setup sketch:

1. Clone and enter the official repo:
   git clone https://github.com/Tencent-Hunyuan/Hunyuan3D-2.git
   cd Hunyuan3D-2

2. Create a Python env:
   python -m venv .venv
   .\.venv\Scripts\Activate.ps1

3. Install PyTorch from https://pytorch.org/get-started/locally/
   Example for CUDA 12.1:
   pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

4. Install Hunyuan3D:
   pip install -r requirements.txt
   pip install -e .

5. Install texture renderer extensions if you need Honey_textured_mv.glb:
   python .\hy3dgen\texgen\custom_rasterizer\setup.py install
   python .\hy3dgen\texgen\differentiable_renderer\setup.py install

6. Run from this Unity project:
   .\Tools\Generation\Hunyuan3D\GenerateHoneyMvGlb.ps1 -PythonExe "C:\Path\To\Hunyuan3D-2\.venv\Scripts\python.exe"

Notes:
- Shape-only generation usually needs about 6 GB VRAM.
- Shape+texture generation usually needs about 16 GB VRAM.
- If side.png is actually a left-side view already, pass -SideSource Left.
- -TextureInputMode FrontLeftBack reuses the same normalized front/left/back views for Paint.
"@
}

$repoRoot = Resolve-RepoRoot
$scriptPath = Join-Path $PSScriptRoot "GenerateHoneyMvGlb.py"
$inputDirFullPath = Resolve-RepoPath -PathValue $InputDir -RepoRoot $repoRoot
$outputDirFullPath = Resolve-RepoPath -PathValue $OutputDir -RepoRoot $repoRoot
$textureInputModeArg = switch ($TextureInputMode) {
    "Front" { "front" }
    "FrontLeftBack" { "front-left-back" }
}

if ($PrintInstallHelp) {
    Write-InstallHelp
    return
}

if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
    throw "Python script not found: $scriptPath"
}

if (-not (Test-Path -LiteralPath $inputDirFullPath -PathType Container)) {
    throw "Input directory not found: $inputDirFullPath"
}

[void](New-Item -ItemType Directory -Path $outputDirFullPath -Force)

$pythonArgs = @(
    $scriptPath,
    "--input-dir", $inputDirFullPath,
    "--output-dir", $outputDirFullPath,
    "--side-source", $SideSource.ToLowerInvariant(),
    "--background-mode", $BackgroundMode.ToLowerInvariant(),
    "--floodfill-threshold", $FloodfillThreshold,
    "--canvas-size", $CanvasSize,
    "--subject-height-ratio", $SubjectHeightRatio,
    "--floor-y-ratio", $FloorYRatio,
    "--texture-input-mode", $textureInputModeArg,
    "--device", $Device,
    "--num-inference-steps", $NumInferenceSteps,
    "--octree-resolution", $OctreeResolution,
    "--num-chunks", $NumChunks,
    "--seed", $Seed
)

if ($SkipTexture) {
    $pythonArgs += "--skip-texture"
}

if ($ReuseWhiteGlb) {
    $pythonArgs += "--reuse-white-glb"
}

if ($NoComponentCleanup) {
    $pythonArgs += "--no-component-cleanup"
}

if ($PrepareOnly) {
    $pythonArgs += "--prepare-only"
}

Push-Location -LiteralPath $repoRoot
try {
    Write-Host "Running: $PythonExe $($pythonArgs -join ' ')"
    & $PythonExe @pythonArgs
    if ($LASTEXITCODE -ne 0) {
        throw "Generation failed with exit code $LASTEXITCODE"
    }
}
finally {
    Pop-Location
}
