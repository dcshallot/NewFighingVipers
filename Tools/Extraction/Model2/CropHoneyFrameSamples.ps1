param(
    [Parameter(Mandatory = $false)]
    [string]$InputRoot = "Reference\Captures\Honey\FrameSamplesRaw",

    [Parameter(Mandatory = $false)]
    [string]$OutputRoot = "Reference\Captures\Honey\FrameSamplesCropped",

    [Parameter(Mandatory = $false)]
    [string]$CropConfigPath = "Tools\Extraction\Model2\HoneyVideoFrameCropConfig.json",

    [Parameter(Mandatory = $false)]
    [switch]$GenerateMissingConfigOnly
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

function Resolve-OrCreateRepoPath {
    param([string]$PathValue)

    if ([System.IO.Path]::IsPathRooted($PathValue)) {
        return [System.IO.Path]::GetFullPath($PathValue)
    }

    return [System.IO.Path]::GetFullPath((Join-Path (Get-Location).Path $PathValue))
}

function Clamp-NormalizedRect {
    param(
        [double]$Value,
        [double]$Fallback
    )

    if ([double]::IsNaN($Value) -or [double]::IsInfinity($Value)) {
        return $Fallback
    }

    if ($Value -lt 0.0) {
        return 0.0
    }

    if ($Value -gt 1.0) {
        return 1.0
    }

    return $Value
}

function New-DefaultCropEntry {
    param([string]$VideoStem)

    [PSCustomObject]@{
        VideoStem = $VideoStem
        Enabled = $true
        CropNormX = 0.25
        CropNormY = 0.05
        CropNormWidth = 0.50
        CropNormHeight = 0.90
        Notes = "Default centered crop. Adjust to keep only Honey full body."
    }
}

function Load-CropConfigMap {
    param(
        [string]$ConfigPath,
        [string[]]$VideoStems
    )

    $configMap = @{}
    if (Test-Path -LiteralPath $ConfigPath) {
        $jsonText = Get-Content -LiteralPath $ConfigPath -Raw
        $loadedEntries = $jsonText | ConvertFrom-Json
        if ($null -ne $loadedEntries) {
            foreach ($entry in @($loadedEntries)) {
                if (-not [string]::IsNullOrWhiteSpace($entry.VideoStem)) {
                    $configMap[$entry.VideoStem] = $entry
                }
            }
        }
    }

    $changed = $false
    foreach ($videoStem in $VideoStems) {
        if (-not $configMap.ContainsKey($videoStem)) {
            $configMap[$videoStem] = New-DefaultCropEntry -VideoStem $videoStem
            $changed = $true
        }
    }

    if ($changed -or -not (Test-Path -LiteralPath $ConfigPath)) {
        $configDir = [System.IO.Path]::GetDirectoryName($ConfigPath)
        if (-not [string]::IsNullOrWhiteSpace($configDir) -and -not (Test-Path -LiteralPath $configDir)) {
            [void](New-Item -ItemType Directory -Path $configDir -Force)
        }

        $configMap.Values |
            Sort-Object VideoStem |
            ConvertTo-Json -Depth 4 |
            Set-Content -LiteralPath $ConfigPath -Encoding UTF8
    }

    return $configMap
}

$inputRootPath = Resolve-OrCreateRepoPath -PathValue $InputRoot
if (-not (Test-Path -LiteralPath $inputRootPath)) {
    throw "InputRoot does not exist: $inputRootPath"
}

$outputRootPath = Resolve-OrCreateRepoPath -PathValue $OutputRoot
if (-not (Test-Path -LiteralPath $outputRootPath)) {
    [void](New-Item -ItemType Directory -Path $outputRootPath -Force)
}

$cropConfigFullPath = Resolve-OrCreateRepoPath -PathValue $CropConfigPath

$videoDirs = Get-ChildItem -LiteralPath $inputRootPath -Directory | Sort-Object Name
if ($videoDirs.Count -eq 0) {
    throw "No per-video frame folders found under $inputRootPath"
}

$configMap = Load-CropConfigMap -ConfigPath $cropConfigFullPath -VideoStems ($videoDirs | Select-Object -ExpandProperty Name)

if ($GenerateMissingConfigOnly) {
    [PSCustomObject]@{
        CropConfigPath = $cropConfigFullPath
        VideoCount = $videoDirs.Count
        Mode = "GenerateMissingConfigOnly"
    } | Format-List *
    return
}

$manifestRows = New-Object System.Collections.Generic.List[object]

foreach ($videoDir in $videoDirs) {
    $entry = $configMap[$videoDir.Name]
    if ($null -eq $entry -or $entry.Enabled -eq $false) {
        continue
    }

    $frames = Get-ChildItem -LiteralPath $videoDir.FullName -Filter 'frame_*.png' -File | Sort-Object Name
    if ($frames.Count -eq 0) {
        continue
    }

    $videoOutputDir = Join-Path $outputRootPath $videoDir.Name
    if (-not (Test-Path -LiteralPath $videoOutputDir)) {
        [void](New-Item -ItemType Directory -Path $videoOutputDir -Force)
    }

    $normX = Clamp-NormalizedRect -Value ([double]$entry.CropNormX) -Fallback 0.25
    $normY = Clamp-NormalizedRect -Value ([double]$entry.CropNormY) -Fallback 0.05
    $normW = Clamp-NormalizedRect -Value ([double]$entry.CropNormWidth) -Fallback 0.50
    $normH = Clamp-NormalizedRect -Value ([double]$entry.CropNormHeight) -Fallback 0.90

    foreach ($frame in $frames) {
        $bitmap = [System.Drawing.Bitmap]::FromFile($frame.FullName)
        try {
            $cropX = [int][Math]::Round($bitmap.Width * $normX)
            $cropY = [int][Math]::Round($bitmap.Height * $normY)
            $cropW = [int][Math]::Round($bitmap.Width * $normW)
            $cropH = [int][Math]::Round($bitmap.Height * $normH)

            if ($cropX -lt 0) { $cropX = 0 }
            if ($cropY -lt 0) { $cropY = 0 }
            if ($cropX -ge $bitmap.Width) { $cropX = [Math]::Max(0, $bitmap.Width - 1) }
            if ($cropY -ge $bitmap.Height) { $cropY = [Math]::Max(0, $bitmap.Height - 1) }
            if ($cropW -lt 1) { $cropW = 1 }
            if ($cropH -lt 1) { $cropH = 1 }
            if (($cropX + $cropW) -gt $bitmap.Width) { $cropW = $bitmap.Width - $cropX }
            if (($cropY + $cropH) -gt $bitmap.Height) { $cropH = $bitmap.Height - $cropY }

            $rect = New-Object System.Drawing.Rectangle($cropX, $cropY, $cropW, $cropH)
            $cropped = $bitmap.Clone($rect, $bitmap.PixelFormat)
            try {
                $outputPath = Join-Path $videoOutputDir $frame.Name
                $cropped.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)

                [void]$manifestRows.Add([PSCustomObject]@{
                    VideoStem = $videoDir.Name
                    FrameName = $frame.Name
                    SourceFrame = $frame.FullName
                    CroppedFrame = $outputPath
                    CropX = $cropX
                    CropY = $cropY
                    CropWidth = $cropW
                    CropHeight = $cropH
                    SourceWidth = $bitmap.Width
                    SourceHeight = $bitmap.Height
                })
            }
            finally {
                $cropped.Dispose()
            }
        }
        finally {
            $bitmap.Dispose()
        }
    }
}

$manifestPath = Join-Path $outputRootPath "_frame_samples_cropped_manifest.csv"
$manifestRows | Export-Csv -LiteralPath $manifestPath -NoTypeInformation -Encoding UTF8

[PSCustomObject]@{
    InputRoot = $inputRootPath
    OutputRoot = $outputRootPath
    CropConfigPath = $cropConfigFullPath
    VideoCount = $videoDirs.Count
    CroppedFrameCount = $manifestRows.Count
    ManifestPath = $manifestPath
} | Format-List *
