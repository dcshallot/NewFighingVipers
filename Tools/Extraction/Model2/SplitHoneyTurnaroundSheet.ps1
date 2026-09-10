param(
    [Parameter(Mandatory = $false)]
    [string]$InputImagePath = "LocalData\Incoming\Honey\TurnaroundRaw\honey_turnaround.png",

    [Parameter(Mandatory = $false)]
    [string]$OutputDir = "LocalData\Generated\Honey\TurnaroundSplit",

    [Parameter(Mandatory = $false)]
    [int]$ForegroundMinChannelThreshold = 225,

    [Parameter(Mandatory = $false)]
    [double]$GuideRowCoverageThreshold = 0.65,

    [Parameter(Mandatory = $false)]
    [int]$CoreColumnMinPixels = 24,

    [Parameter(Mandatory = $false)]
    [int]$ExpandColumnMinPixels = 2,

    [Parameter(Mandatory = $false)]
    [int]$MergeGapPixels = 180,

    [Parameter(Mandatory = $false)]
    [int]$PaddingPixels = 96
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\..\.."))

function Resolve-RepoPath {
    param([string]$PathValue)

    if ([System.IO.Path]::IsPathRooted($PathValue)) {
        return (Resolve-Path -LiteralPath $PathValue).Path
    }

    return (Resolve-Path -LiteralPath (Join-Path $repoRoot $PathValue)).Path
}

function Test-ForegroundPixel {
    param(
        [System.Drawing.Color]$Color,
        [int]$MinChannelThreshold
    )

    $minChannel = [Math]::Min([int]$Color.R, [Math]::Min([int]$Color.G, [int]$Color.B))
    return $minChannel -le $MinChannelThreshold
}

$inputImageFullPath = Resolve-RepoPath -PathValue $InputImagePath
$outputDirFullPath = if ([System.IO.Path]::IsPathRooted($OutputDir)) { [System.IO.Path]::GetFullPath($OutputDir) } else { [System.IO.Path]::GetFullPath((Join-Path $repoRoot $OutputDir)) }
$localDataRoot = [System.IO.Path]::GetFullPath((Join-Path $repoRoot "LocalData")).TrimEnd([char[]]@('\', '/'))
$localDataPrefix = $localDataRoot + [System.IO.Path]::DirectorySeparatorChar
if (-not $outputDirFullPath.StartsWith($localDataPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "OutputDir must stay under LocalData: $outputDirFullPath"
}
if (-not (Test-Path -LiteralPath $outputDirFullPath)) {
    [void](New-Item -ItemType Directory -Path $outputDirFullPath -Force)
}

$sheet = [System.Drawing.Bitmap]::FromFile($inputImageFullPath)
try {
    $width = $sheet.Width
    $height = $sheet.Height

    $ignoreRow = New-Object bool[] $height
    $columnCounts = New-Object int[] $width

    for ($y = 0; $y -lt $height; $y++) {
        $foregroundCount = 0
        for ($x = 0; $x -lt $width; $x++) {
            $color = $sheet.GetPixel($x, $y)
            if (Test-ForegroundPixel -Color $color -MinChannelThreshold $ForegroundMinChannelThreshold) {
                $foregroundCount++
            }
        }

        if ($foregroundCount -ge [int][Math]::Round($width * $GuideRowCoverageThreshold)) {
            $ignoreRow[$y] = $true
        }
    }

    for ($x = 0; $x -lt $width; $x++) {
        $count = 0
        for ($y = 0; $y -lt $height; $y++) {
            if ($ignoreRow[$y]) {
                continue
            }

            $color = $sheet.GetPixel($x, $y)
            if (Test-ForegroundPixel -Color $color -MinChannelThreshold $ForegroundMinChannelThreshold) {
                $count++
            }
        }
        $columnCounts[$x] = $count
    }

    $rawSpans = New-Object System.Collections.Generic.List[object]
    $spanStart = -1
    for ($x = 0; $x -lt $width; $x++) {
        $isActive = $columnCounts[$x] -ge $CoreColumnMinPixels
        if ($isActive -and $spanStart -lt 0) {
            $spanStart = $x
        }
        elseif (-not $isActive -and $spanStart -ge 0) {
            [void]$rawSpans.Add([PSCustomObject]@{ StartX = $spanStart; EndX = $x - 1 })
            $spanStart = -1
        }
    }
    if ($spanStart -ge 0) {
        [void]$rawSpans.Add([PSCustomObject]@{ StartX = $spanStart; EndX = $width - 1 })
    }

    $expandedSpans = New-Object System.Collections.Generic.List[object]
    foreach ($span in $rawSpans) {
        $startX = [int]$span.StartX
        $endX = [int]$span.EndX

        while ($startX -gt 0 -and $columnCounts[$startX - 1] -ge $ExpandColumnMinPixels) {
            $startX--
        }
        while ($endX -lt ($width - 1) -and $columnCounts[$endX + 1] -ge $ExpandColumnMinPixels) {
            $endX++
        }

        [void]$expandedSpans.Add([PSCustomObject]@{
            StartX = $startX
            EndX = $endX
            Width = $endX - $startX + 1
        })
    }

    $mergedSpans = New-Object System.Collections.Generic.List[object]
    foreach ($span in ($expandedSpans | Sort-Object StartX)) {
        if ($mergedSpans.Count -eq 0) {
            [void]$mergedSpans.Add([PSCustomObject]@{ StartX = [int]$span.StartX; EndX = [int]$span.EndX })
            continue
        }

        $last = $mergedSpans[$mergedSpans.Count - 1]
        if (([int]$span.StartX - [int]$last.EndX - 1) -le $MergeGapPixels) {
            if ([int]$span.EndX -gt [int]$last.EndX) {
                $last.EndX = [int]$span.EndX
            }
        }
        else {
            [void]$mergedSpans.Add([PSCustomObject]@{ StartX = [int]$span.StartX; EndX = [int]$span.EndX })
        }
    }

    $subjectSpans =
        $mergedSpans |
        ForEach-Object {
            [PSCustomObject]@{
                StartX = [int]$_.StartX
                EndX = [int]$_.EndX
                Width = [int]$_.EndX - [int]$_.StartX + 1
                CenterX = ([int]$_.StartX + [int]$_.EndX) / 2.0
            }
        } |
        Where-Object { $_.Width -ge 120 } |
        Sort-Object Width -Descending |
        Select-Object -First 3 |
        Sort-Object CenterX

    $subjectSpanCount = if ($null -eq $subjectSpans) { 0 } else { @($subjectSpans).Count }
    if ($subjectSpanCount -ne 3) {
        throw "Expected 3 subject spans, got $subjectSpanCount. Try adjusting thresholds."
    }

    $views = @(
        @{ Name = "front"; Span = $subjectSpans[0] },
        @{ Name = "side"; Span = $subjectSpans[1] },
        @{ Name = "back"; Span = $subjectSpans[2] }
    )

    $rows = New-Object System.Collections.Generic.List[object]

    foreach ($view in $views) {
        $cropX = [Math]::Max(0, [int]$view.Span.StartX - $PaddingPixels)
        $cropRight = [Math]::Min($width - 1, [int]$view.Span.EndX + $PaddingPixels)
        $cropWidth = $cropRight - $cropX + 1

        $rect = New-Object System.Drawing.Rectangle($cropX, 0, $cropWidth, $height)
        $crop = $sheet.Clone($rect, $sheet.PixelFormat)
        try {
            $outputPath = Join-Path $outputDirFullPath ("{0}.png" -f $view.Name)
            $crop.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)

            [void]$rows.Add([PSCustomObject]@{
                View = $view.Name
                OutputPath = $outputPath
                X = $cropX
                Y = 0
                Width = $cropWidth
                Height = $height
                SourceSpanStartX = [int]$view.Span.StartX
                SourceSpanEndX = [int]$view.Span.EndX
            })
        }
        finally {
            $crop.Dispose()
        }
    }

    $manifestPath = Join-Path $outputDirFullPath "_turnaround_split_manifest.csv"
    $rows | Export-Csv -LiteralPath $manifestPath -NoTypeInformation -Encoding UTF8

    [PSCustomObject]@{
        InputImagePath = $inputImageFullPath
        OutputDir = $outputDirFullPath
        ManifestPath = $manifestPath
        SourceWidth = $width
        SourceHeight = $height
        ViewCount = $rows.Count
    } | Format-List *
}
finally {
    $sheet.Dispose()
}
