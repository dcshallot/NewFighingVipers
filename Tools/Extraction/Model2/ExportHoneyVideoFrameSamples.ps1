param(
    [Parameter(Mandatory = $false)]
    [string]$VideoDir = "LocalData\Raw\VideoRefs",

    [Parameter(Mandatory = $false)]
    [string]$OutputRoot = "LocalData\Captures\Honey\FrameSamplesRaw",

    [Parameter(Mandatory = $false)]
    [int]$IntervalSeconds = 3,

    [Parameter(Mandatory = $false)]
    [string]$FfmpegPath = ""
)

$ErrorActionPreference = "Stop"
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\..\.."))

function Resolve-WorkspacePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PathValue,

        [switch]$MustExist
    )

    $candidate = if ([System.IO.Path]::IsPathRooted($PathValue)) {
        $PathValue
    }
    else {
        Join-Path $repoRoot $PathValue
    }

    $fullPath = [System.IO.Path]::GetFullPath($candidate)
    $fullRoot = [System.IO.Path]::GetFullPath($repoRoot).TrimEnd([char[]]@('\', '/'))
    $rootPrefix = $fullRoot + [System.IO.Path]::DirectorySeparatorChar
    $isRoot = $fullPath.Equals($fullRoot, [System.StringComparison]::OrdinalIgnoreCase)
    $isDescendant = $fullPath.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)
    if (-not $isRoot -and -not $isDescendant) {
        throw "Refusing to operate outside workspace: $fullPath"
    }

    if ($MustExist -and -not (Test-Path -LiteralPath $fullPath)) {
        throw "Path not found: $fullPath"
    }

    return $fullPath
}

function Resolve-FfmpegExe {
    param([string]$PreferredPath)

    if (-not [string]::IsNullOrWhiteSpace($PreferredPath)) {
        $candidate = if ([System.IO.Path]::IsPathRooted($PreferredPath)) {
            $PreferredPath
        }
        else {
            Join-Path $repoRoot $PreferredPath
        }
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
        throw "Configured ffmpeg executable not found."
    }

    $pathCommand = Get-Command ffmpeg -ErrorAction SilentlyContinue
    if ($null -ne $pathCommand -and -not [string]::IsNullOrWhiteSpace($pathCommand.Source)) {
        return $pathCommand.Source
    }

    throw "ffmpeg not found on PATH. Install it or pass -FfmpegPath explicitly."
}

if ($IntervalSeconds -le 0) {
    throw "IntervalSeconds must be > 0"
}

$videoDirPath = Resolve-WorkspacePath -PathValue $VideoDir -MustExist
$outputRootPath = Resolve-WorkspacePath -PathValue $OutputRoot
$localDataRoot = [System.IO.Path]::GetFullPath((Join-Path $repoRoot "LocalData")).TrimEnd([char[]]@('\', '/'))
$localDataPrefix = $localDataRoot + [System.IO.Path]::DirectorySeparatorChar
if (-not $outputRootPath.StartsWith($localDataPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "OutputRoot must stay under LocalData: $outputRootPath"
}
if (-not (Test-Path -LiteralPath $outputRootPath)) {
    [void](New-Item -ItemType Directory -Path $outputRootPath -Force)
}

$ffmpegExe = Resolve-FfmpegExe -PreferredPath $FfmpegPath
$videos = Get-ChildItem -LiteralPath $videoDirPath -Filter '*.mp4' -File | Sort-Object Name
if ($videos.Count -eq 0) {
    throw "No mp4 files found in $videoDirPath"
}

$manifestRows = New-Object System.Collections.Generic.List[object]

foreach ($video in $videos) {
    $videoStem = [System.IO.Path]::GetFileNameWithoutExtension($video.Name)
    $videoOutputDir = Join-Path $outputRootPath $videoStem
    if (-not (Test-Path -LiteralPath $videoOutputDir)) {
        [void](New-Item -ItemType Directory -Path $videoOutputDir -Force)
    }
    else {
        Get-ChildItem -LiteralPath $videoOutputDir -Filter 'frame_*.png' -File | Remove-Item -Force
    }

    $outputPattern = Join-Path $videoOutputDir "frame_%05d.png"

    $args = @(
        "-hide_banner",
        "-loglevel", "error",
        "-i", $video.FullName,
        "-vf", ("fps=1/{0}" -f $IntervalSeconds),
        "-start_number", "0",
        "-y",
        $outputPattern
    )

    & $ffmpegExe @args
    if ($LASTEXITCODE -ne 0) {
        throw "ffmpeg failed for $($video.FullName) with exit code $LASTEXITCODE"
    }

    $frames = Get-ChildItem -LiteralPath $videoOutputDir -Filter 'frame_*.png' -File | Sort-Object Name
    foreach ($frame in $frames) {
        $frameIndex = [int]([System.IO.Path]::GetFileNameWithoutExtension($frame.Name).Substring(6))
        [void]$manifestRows.Add([PSCustomObject]@{
            VideoName = $video.Name
            VideoStem = $videoStem
            FrameName = $frame.Name
            FramePath = $frame.FullName
            ApproxTimestampSec = $frameIndex * $IntervalSeconds
        })
    }
}

$manifestPath = Join-Path $outputRootPath "_frame_samples_raw_manifest.csv"
$manifestRows | Export-Csv -LiteralPath $manifestPath -NoTypeInformation -Encoding UTF8

[PSCustomObject]@{
    FfmpegPath = $ffmpegExe
    VideoDir = $videoDirPath
    OutputRoot = $outputRootPath
    IntervalSeconds = $IntervalSeconds
    VideoCount = $videos.Count
    FrameCount = $manifestRows.Count
    ManifestPath = $manifestPath
} | Format-List *
