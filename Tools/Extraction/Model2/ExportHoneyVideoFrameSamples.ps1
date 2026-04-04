param(
    [Parameter(Mandatory = $false)]
    [string]$VideoDir = "Reference\OriginalAssets\Textures\FightingVipers\Honey\Honey_Master_TextureSet\_LocalScreenshots\VideoRefs",

    [Parameter(Mandatory = $false)]
    [string]$OutputRoot = "Reference\Captures\Honey\FrameSamplesRaw",

    [Parameter(Mandatory = $false)]
    [int]$IntervalSeconds = 3,

    [Parameter(Mandatory = $false)]
    [string]$FfmpegPath = ""
)

$ErrorActionPreference = "Stop"

function Resolve-RepoPath {
    param([string]$PathValue)

    if ([System.IO.Path]::IsPathRooted($PathValue)) {
        return (Resolve-Path -LiteralPath $PathValue).Path
    }

    return (Resolve-Path -LiteralPath (Join-Path (Get-Location).Path $PathValue)).Path
}

function Resolve-FfmpegExe {
    param([string]$PreferredPath)

    if (-not [string]::IsNullOrWhiteSpace($PreferredPath)) {
        if ([System.IO.Path]::IsPathRooted($PreferredPath) -and (Test-Path -LiteralPath $PreferredPath)) {
            return (Resolve-Path -LiteralPath $PreferredPath).Path
        }

        $candidate = Join-Path (Get-Location).Path $PreferredPath
        if (Test-Path -LiteralPath $candidate) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    $repoCandidate = Join-Path (Get-Location).Path "Resources\ffmpeg\bin\ffmpeg.exe"
    if (Test-Path -LiteralPath $repoCandidate) {
        return (Resolve-Path -LiteralPath $repoCandidate).Path
    }

    $pathCommand = Get-Command ffmpeg -ErrorAction SilentlyContinue
    if ($null -ne $pathCommand -and -not [string]::IsNullOrWhiteSpace($pathCommand.Source)) {
        return $pathCommand.Source
    }

    throw "ffmpeg.exe not found. Put ffmpeg at Resources\ffmpeg\bin\ffmpeg.exe or pass -FfmpegPath explicitly."
}

if ($IntervalSeconds -le 0) {
    throw "IntervalSeconds must be > 0"
}

$videoDirPath = Resolve-RepoPath -PathValue $VideoDir
$outputRootPath = Join-Path (Get-Location).Path $OutputRoot
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
