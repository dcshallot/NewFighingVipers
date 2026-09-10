param(
    [string]$TextureSetDir = "",
    [string]$OutputDir = "",
    [int]$SheetColumns = 2,
    [int]$ThumbSize = 128
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

function Get-RepoRoot {
    $scriptDir = Split-Path -Parent $PSCommandPath
    return (Resolve-Path -LiteralPath (Join-Path $scriptDir "..\..\..")).Path
}

function Assert-ChildPath {
    param(
        [string]$ParentPath,
        [string]$ChildPath
    )

    $fullParent = [System.IO.Path]::GetFullPath($ParentPath).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    $fullChild = [System.IO.Path]::GetFullPath($ChildPath)
    $prefix = $fullParent + [System.IO.Path]::DirectorySeparatorChar

    if (-not $fullChild.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Output path is outside texture-set directory: $fullChild"
    }
}

function Get-TextureRelativePath {
    param([string]$OutputFile)

    $normalized = $OutputFile.Replace("/", "\")
    foreach ($marker in @("\Main\", "\ColorAlt_P2\")) {
        $index = $normalized.IndexOf($marker, [System.StringComparison]::OrdinalIgnoreCase)
        if ($index -ge 0) {
            return $normalized.Substring($index + 1)
        }
    }

    throw "Cannot derive texture-relative path from manifest OutputFile: $OutputFile"
}

function Convert-HsvToColor {
    param(
        [double]$Hue,
        [double]$Saturation,
        [double]$Value
    )

    $c = $Value * $Saturation
    $x = $c * (1.0 - [Math]::Abs(((($Hue / 60.0) % 2.0) - 1.0)))
    $m = $Value - $c

    $r1 = 0.0
    $g1 = 0.0
    $b1 = 0.0

    if ($Hue -lt 60.0) {
        $r1 = $c; $g1 = $x; $b1 = 0.0
    } elseif ($Hue -lt 120.0) {
        $r1 = $x; $g1 = $c; $b1 = 0.0
    } elseif ($Hue -lt 180.0) {
        $r1 = 0.0; $g1 = $c; $b1 = $x
    } elseif ($Hue -lt 240.0) {
        $r1 = 0.0; $g1 = $x; $b1 = $c
    } elseif ($Hue -lt 300.0) {
        $r1 = $x; $g1 = 0.0; $b1 = $c
    } else {
        $r1 = $c; $g1 = 0.0; $b1 = $x
    }

    $r = [int][Math]::Round(($r1 + $m) * 255.0)
    $g = [int][Math]::Round(($g1 + $m) * 255.0)
    $b = [int][Math]::Round(($b1 + $m) * 255.0)

    $r = [Math]::Max(0, [Math]::Min(255, $r))
    $g = [Math]::Max(0, [Math]::Min(255, $g))
    $b = [Math]::Max(0, [Math]::Min(255, $b))

    return [System.Drawing.Color]::FromArgb(255, $r, $g, $b)
}

function Get-StableDebugColor {
    param([string]$NormId)

    $hash = 2166136261L
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($NormId.ToUpperInvariant())
    foreach ($byteValue in $bytes) {
        $hash = (($hash -bxor $byteValue) * 16777619L) -band 0xFFFFFFFFL
    }

    $hue = [double]($hash % 360L)
    return Convert-HsvToColor -Hue $hue -Saturation 0.82 -Value 1.0
}

function Get-PartMapping {
    param([string]$MappingPath)

    $mapping = @{}
    if (-not (Test-Path -LiteralPath $MappingPath)) {
        return $mapping
    }

    foreach ($line in Get-Content -LiteralPath $MappingPath -Encoding utf8) {
        if ($line -notmatch '^\|\s*([^|]+?)\s*\|\s*`?([^`|]+?)`?\s*\|\s*([^|]+?)\s*\|\s*(High|Mid|Low)\s*\|\s*([^|]*?)\s*\|\s*([^|]*?)\s*\|') {
            continue
        }

        $normId = $matches[2].Trim()
        $mapping[$normId] = [pscustomobject]@{
            Category = $matches[1].Trim()
            SuspectedPart = $matches[3].Trim()
            Confidence = $matches[4].Trim()
            Evidence = $matches[5].Trim()
            ToVerifyNext = $matches[6].Trim()
        }
    }

    return $mapping
}

function Convert-ToFalseColorTexture {
    param(
        [string]$SourcePath,
        [string]$DestinationPath,
        [System.Drawing.Color]$DebugColor
    )

    $src = [System.Drawing.Bitmap]::FromFile($SourcePath)
    $dst = $null

    try {
        $dst = [System.Drawing.Bitmap]::new($src.Width, $src.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)

        for ($y = 0; $y -lt $src.Height; $y++) {
            for ($x = 0; $x -lt $src.Width; $x++) {
                $pixel = $src.GetPixel($x, $y)
                if ($pixel.A -eq 0) {
                    $dst.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
                    continue
                }

                $luma = ((0.2126 * $pixel.R) + (0.7152 * $pixel.G) + (0.0722 * $pixel.B)) / 255.0
                $scale = 0.25 + (0.75 * $luma)
                $r = [int][Math]::Round($DebugColor.R * $scale)
                $g = [int][Math]::Round($DebugColor.G * $scale)
                $b = [int][Math]::Round($DebugColor.B * $scale)
                $r = [Math]::Max(0, [Math]::Min(255, $r))
                $g = [Math]::Max(0, [Math]::Min(255, $g))
                $b = [Math]::Max(0, [Math]::Min(255, $b))

                $dst.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($pixel.A, $r, $g, $b))
            }
        }

        $destDir = Split-Path -Parent $DestinationPath
        if (-not (Test-Path -LiteralPath $destDir)) {
            New-Item -ItemType Directory -Force -Path $destDir | Out-Null
        }

        $dst.Save($DestinationPath, [System.Drawing.Imaging.ImageFormat]::Png)
    } finally {
        if ($null -ne $dst) {
            $dst.Dispose()
        }
        $src.Dispose()
    }
}

function Draw-ImageFit {
    param(
        [System.Drawing.Graphics]$Graphics,
        [System.Drawing.Image]$Image,
        [System.Drawing.Rectangle]$TargetRect
    )

    $scaleX = $TargetRect.Width / [double]$Image.Width
    $scaleY = $TargetRect.Height / [double]$Image.Height
    $scale = [Math]::Min($scaleX, $scaleY)
    $drawW = [int][Math]::Max(1, [Math]::Round($Image.Width * $scale))
    $drawH = [int][Math]::Max(1, [Math]::Round($Image.Height * $scale))
    $x = $TargetRect.X + [int][Math]::Floor(($TargetRect.Width - $drawW) / 2.0)
    $y = $TargetRect.Y + [int][Math]::Floor(($TargetRect.Height - $drawH) / 2.0)
    $Graphics.DrawImage($Image, $x, $y, $drawW, $drawH)
}

function New-LegendSheet {
    param(
        [object[]]$Rows,
        [string]$SheetPath,
        [int]$Columns,
        [int]$Thumb
    )

    $tileW = 620
    $tileH = [Math]::Max(220, $Thumb + 80)
    $rowCount = [int][Math]::Ceiling($Rows.Count / [double]$Columns)
    $sheetW = $tileW * $Columns
    $sheetH = [Math]::Max(1, $rowCount * $tileH)

    $bmp = [System.Drawing.Bitmap]::new($sheetW, $sheetH, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $bgBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 18, 18, 18))
    $panelBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 36, 36, 36))
    $textBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 235, 235, 235))
    $mutedBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 180, 180, 180))
    $fontTitle = New-Object System.Drawing.Font("Consolas", 11, [System.Drawing.FontStyle]::Bold)
    $fontBody = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Regular)

    try {
        $g.Clear([System.Drawing.Color]::FromArgb(255, 18, 18, 18))
        $g.FillRectangle($bgBrush, 0, 0, $sheetW, $sheetH)

        for ($i = 0; $i -lt $Rows.Count; $i++) {
            $row = $Rows[$i]
            $colIndex = $i % $Columns
            $rowIndex = [int][Math]::Floor($i / [double]$Columns)
            $x = $colIndex * $tileW
            $y = $rowIndex * $tileH

            $panelRect = [System.Drawing.Rectangle]::new([int]($x + 8), [int]($y + 8), [int]($tileW - 16), [int]($tileH - 16))
            $g.FillRectangle($panelBrush, $panelRect)

            $borderPen = New-Object System.Drawing.Pen($row.DebugColor, 3)
            try {
                $g.DrawRectangle($borderPen, $panelRect)
            } finally {
                $borderPen.Dispose()
            }

            $swatchBrush = New-Object System.Drawing.SolidBrush($row.DebugColor)
            try {
                $g.FillRectangle($swatchBrush, $x + 20, $y + 20, 48, 48)
            } finally {
                $swatchBrush.Dispose()
            }

            $orig = [System.Drawing.Bitmap]::FromFile($row.SourcePath)
            $debug = [System.Drawing.Bitmap]::FromFile($row.DebugPath)
            try {
                Draw-ImageFit -Graphics $g -Image $orig -TargetRect ([System.Drawing.Rectangle]::new([int]($x + 80), [int]($y + 20), [int]$Thumb, [int]$Thumb))
                Draw-ImageFit -Graphics $g -Image $debug -TargetRect ([System.Drawing.Rectangle]::new([int]($x + 92 + $Thumb), [int]($y + 20), [int]$Thumb, [int]$Thumb))
            } finally {
                $orig.Dispose()
                $debug.Dispose()
            }

            $textX = $x + 104 + ($Thumb * 2)
            $g.DrawString("$($row.Category)  $($row.NormId)  $($row.VariantKind)", $fontTitle, $textBrush, $textX, $y + 18)
            $g.DrawString("$($row.Confidence)  $($row.DebugColorHex)", $fontBody, $textBrush, $textX, $y + 46)
            $g.DrawString("Part: $($row.SuspectedPart)", $fontBody, $textBrush, $textX, $y + 72)
            $g.DrawString("File: $($row.SourceRelPath)", $fontBody, $mutedBrush, $textX, $y + 112)
            $g.DrawString("Todo: $($row.ToVerifyNext)", $fontBody, $mutedBrush, $x + 20, $y + $Thumb + 34)
        }

        $sheetDir = Split-Path -Parent $SheetPath
        if (-not (Test-Path -LiteralPath $sheetDir)) {
            New-Item -ItemType Directory -Force -Path $sheetDir | Out-Null
        }
        $bmp.Save($SheetPath, [System.Drawing.Imaging.ImageFormat]::Png)
    } finally {
        $fontBody.Dispose()
        $fontTitle.Dispose()
        $mutedBrush.Dispose()
        $textBrush.Dispose()
        $panelBrush.Dispose()
        $bgBrush.Dispose()
        $g.Dispose()
        $bmp.Dispose()
    }
}

$repoRoot = Get-RepoRoot
if ([string]::IsNullOrWhiteSpace($TextureSetDir)) {
    $TextureSetDir = Join-Path $repoRoot "LocalData\Raw\Model2\Honey\Honey_Master_TextureSet"
}

$textureSetPath = (Resolve-Path -LiteralPath $TextureSetDir).Path
$localDataRoot = [System.IO.Path]::GetFullPath((Join-Path $repoRoot "LocalData")).TrimEnd([char[]]@('\', '/'))
$localDataPrefix = $localDataRoot + [System.IO.Path]::DirectorySeparatorChar
if (-not $textureSetPath.StartsWith($localDataPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "TextureSetDir must stay under LocalData: $textureSetPath"
}
if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Join-Path $textureSetPath "_Generated\FalseColorUvCheck_v1"
}
$outputPath = [System.IO.Path]::GetFullPath($OutputDir)
Assert-ChildPath -ParentPath $textureSetPath -ChildPath $outputPath

$manifestPath = Join-Path $textureSetPath "_manifest.csv"
$mappingPath = Join-Path $textureSetPath "_part_mapping_v1.md"
if (-not (Test-Path -LiteralPath $manifestPath)) {
    throw "Manifest not found: $manifestPath"
}

if (Test-Path -LiteralPath $outputPath) {
    Remove-Item -LiteralPath $outputPath -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $outputPath | Out-Null

$mapping = Get-PartMapping -MappingPath $mappingPath
$manifestRows = Import-Csv -LiteralPath $manifestPath

$records = @()
foreach ($row in $manifestRows) {
    if ($row.VariantKind -ne "Main" -and $row.VariantKind -ne "ColorAlt_P2") {
        continue
    }

    $sourceRelPath = Get-TextureRelativePath -OutputFile $row.OutputFile
    $sourcePath = Join-Path $textureSetPath $sourceRelPath
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "Source texture not found: $sourcePath"
    }

    $debugPath = Join-Path (Join-Path $outputPath "Textures") $sourceRelPath
    $debugColor = Get-StableDebugColor -NormId $row.NormId
    Convert-ToFalseColorTexture -SourcePath $sourcePath -DestinationPath $debugPath -DebugColor $debugColor

    $mapEntry = $null
    if ($mapping.ContainsKey($row.NormId)) {
        $mapEntry = $mapping[$row.NormId]
    }

    $records += [pscustomobject]@{
        Category = $row.Category
        NormId = $row.NormId
        VariantKind = $row.VariantKind
        Width = [int]$row.Width
        Height = [int]$row.Height
        DebugColor = $debugColor
        DebugColorHex = ("#{0:X2}{1:X2}{2:X2}" -f $debugColor.R, $debugColor.G, $debugColor.B)
        SuspectedPart = if ($null -ne $mapEntry) { $mapEntry.SuspectedPart } else { "" }
        Confidence = if ($null -ne $mapEntry) { $mapEntry.Confidence } else { "" }
        Evidence = if ($null -ne $mapEntry) { $mapEntry.Evidence } else { "" }
        ToVerifyNext = if ($null -ne $mapEntry) { $mapEntry.ToVerifyNext } else { "" }
        SourceRelPath = $sourceRelPath
        DebugRelPath = $debugPath.Substring($outputPath.Length + 1)
        SourcePath = $sourcePath
        DebugPath = $debugPath
    }
}

$records = $records | Sort-Object Category, NormId, VariantKind, SourceRelPath

$legendRows = @()
foreach ($record in $records) {
    $legendRows += [pscustomobject]@{
        Category = $record.Category
        NormId = $record.NormId
        VariantKind = $record.VariantKind
        DebugColorHex = $record.DebugColorHex
        Width = $record.Width
        Height = $record.Height
        SuspectedPart = $record.SuspectedPart
        Confidence = $record.Confidence
        Evidence = $record.Evidence
        ToVerifyNext = $record.ToVerifyNext
        SourceRelPath = $record.SourceRelPath
        DebugRelPath = $record.DebugRelPath
    }
}

$legendPath = Join-Path $outputPath "_false_color_legend.csv"
$legendRows | Export-Csv -LiteralPath $legendPath -NoTypeInformation -Encoding UTF8

$sheetPath = Join-Path $outputPath "_false_color_sheet.png"
New-LegendSheet -Rows $records -SheetPath $sheetPath -Columns $SheetColumns -Thumb $ThumbSize

Write-Output "Generated false-color UV debug set:"
Write-Output "  $outputPath"
Write-Output "Legend:"
Write-Output "  $legendPath"
Write-Output "Sheet:"
Write-Output "  $sheetPath"
Write-Output "Textures:"
Write-Output "  $(Join-Path $outputPath 'Textures')"
Write-Output "Count:"
Write-Output "  $($records.Count)"
