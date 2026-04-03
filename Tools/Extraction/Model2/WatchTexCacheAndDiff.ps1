param(
    [string]$SessionTag = 'HoneyManual',
    [int]$StableSeconds = 2,
    [int]$PollMilliseconds = 500,
    [switch]$Once,
    [string]$TexCacheDir = '',
    [string]$ManifestPath = '',
    [string]$OutputRoot = '',
    [int]$SheetColumns = 6,
    [int]$SheetRows = 6
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
if ([string]::IsNullOrWhiteSpace($TexCacheDir)) {
    $TexCacheDir = Join-Path $repoRoot 'Resources\M2emulator\TEXCACHE'
}
if ([string]::IsNullOrWhiteSpace($ManifestPath)) {
    $ManifestPath = Join-Path $repoRoot 'Reference\OriginalAssets\Textures\FightingVipers\Honey\Honey_Master_TextureSet\_manifest.csv'
}
if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $OutputRoot = Join-Path $repoRoot 'Reference\OriginalAssets\Textures\FightingVipers\Honey\Honey_Master_TextureSet\_IncomingDumpAuto'
}

function Resolve-WorkspacePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [switch]$MustExist
    )

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $fullRoot = [System.IO.Path]::GetFullPath($repoRoot)
    if (-not $fullPath.StartsWith($fullRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to operate outside workspace: $fullPath"
    }

    if ($MustExist -and -not (Test-Path -LiteralPath $fullPath)) {
        throw "Path not found: $fullPath"
    }

    return $fullPath
}

function Get-NormIdFromSourceId {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceId
    )

    if ($SourceId.Length -eq 8 -and $SourceId.StartsWith('1')) {
        return $SourceId.Substring(1)
    }

    return $SourceId
}

function Get-LooseSlotId {
    param(
        [Parameter(Mandatory = $true)]
        [string]$NormId
    )

    if ($NormId.Length -gt 6) {
        return $NormId.Substring($NormId.Length - 6)
    }

    return $NormId
}

function Get-FileSha256 {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    $sha = [System.Security.Cryptography.SHA256]::Create()
    $stream = [System.IO.File]::OpenRead($FilePath)
    try {
        return ([System.BitConverter]::ToString($sha.ComputeHash($stream)) -replace '-', '')
    } finally {
        $stream.Dispose()
        $sha.Dispose()
    }
}

function Get-ImageInfo {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    if (-not (Test-Path -LiteralPath $FilePath)) {
        throw "Missing image: $FilePath"
    }

    $img = [System.Drawing.Image]::FromFile($FilePath)
    try {
        return [PSCustomObject]@{
            Width = $img.Width
            Height = $img.Height
        }
    } finally {
        $img.Dispose()
    }
}

function Import-ManifestIndex {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CsvPath
    )

    if (-not (Test-Path -LiteralPath $CsvPath)) {
        throw "Manifest not found: $CsvPath"
    }

    $hashSet = @{}
    $normSet = @{}
    $tailMap = @{}
    foreach ($row in (Import-Csv -LiteralPath $CsvPath)) {
        if (-not [string]::IsNullOrWhiteSpace($row.ContentHash)) {
            $hashSet[$row.ContentHash] = $true
        }
        if (-not [string]::IsNullOrWhiteSpace($row.NormId)) {
            $normSet[$row.NormId] = $true
            $looseSlotId = Get-LooseSlotId -NormId $row.NormId
            if (-not $tailMap.ContainsKey($looseSlotId)) {
                $tailMap[$looseSlotId] = [System.Collections.Generic.HashSet[string]]::new()
            }
            [void]$tailMap[$looseSlotId].Add($row.NormId)
        }
    }

    return [PSCustomObject]@{
        ContentHash = $hashSet
        NormId = $normSet
        LooseSlot = $tailMap
    }
}

function Test-FilesUnlocked {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.IO.FileInfo[]]$Files
    )

    foreach ($file in $Files) {
        try {
            $stream = [System.IO.File]::Open($file.FullName, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::None)
            $stream.Dispose()
        } catch {
            return $false
        }
    }

    return $true
}

function Get-TexCacheSignature {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.IO.FileInfo[]]$Files
    )

    if (-not $Files -or $Files.Count -eq 0) {
        return ''
    }

    $maxWrite = ($Files | Measure-Object -Property LastWriteTimeUtc -Maximum).Maximum.ToString('o')
    $totalBytes = ($Files | Measure-Object -Property Length -Sum).Sum
    $names = ($Files | Select-Object -ExpandProperty Name) -join '|'
    return "$($Files.Count)|$maxWrite|$totalBytes|$names"
}

function New-CandidateSheets {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Rows,

        [Parameter(Mandatory = $true)]
        [string]$ReviewDir
    )

    New-Item -ItemType Directory -Force -Path $ReviewDir | Out-Null
    Get-ChildItem -LiteralPath $ReviewDir -File -Filter 'candidate_sheet_*.png' |
        Remove-Item -Force

    $items = @($Rows | Where-Object { $_.Status -ne 'ExactDuplicate' } | Sort-Object LastWriteTime, Bytes, FileName)
    if ($items.Count -eq 0) {
        return 0
    }

    $thumbSize = 96
    $cellWidth = 128
    $cellHeight = 180
    $labelHeight = 68
    $pageSize = $SheetColumns * $SheetRows
    $sheetWidth = [int]($SheetColumns * $cellWidth)
    $sheetHeight = [int]($SheetRows * $cellHeight)
    $font = [System.Drawing.Font]::new('Consolas', 8)
    $brush = [System.Drawing.Brushes]::White
    $pageCount = 0

    try {
        for ($pageIndex = 0; ($pageIndex * $pageSize) -lt $items.Count; $pageIndex++) {
            $pageItems = @($items | Select-Object -Skip ($pageIndex * $pageSize) -First $pageSize)
            $bmp = [System.Drawing.Bitmap]::new($sheetWidth, $sheetHeight)
            $graphics = [System.Drawing.Graphics]::FromImage($bmp)
            try {
                $graphics.Clear([System.Drawing.Color]::FromArgb(30, 30, 30))

                for ($i = 0; $i -lt $pageItems.Count; $i++) {
                    $item = $pageItems[$i]
                    $x = [int](($i % $SheetColumns) * $cellWidth)
                    $y = [int]([Math]::Floor($i / [double]$SheetColumns) * $cellHeight)

                    $graphics.FillRectangle([System.Drawing.Brushes]::DimGray, $x + 4, $y + 4, $thumbSize, $thumbSize)

                    if (-not (Test-Path -LiteralPath $item.FullPath)) {
                        throw "Missing candidate image: $($item.FullPath)"
                    }

                    $img = [System.Drawing.Image]::FromFile($item.FullPath)
                    try {
                        $scale = [Math]::Min($thumbSize / [double]$img.Width, $thumbSize / [double]$img.Height)
                        $drawWidth = [Math]::Max(1, [int]($img.Width * $scale))
                        $drawHeight = [Math]::Max(1, [int]($img.Height * $scale))
                        $drawX = $x + 4 + [int](($thumbSize - $drawWidth) / 2)
                        $drawY = $y + 4 + [int](($thumbSize - $drawHeight) / 2)
                        $graphics.DrawImage($img, $drawX, $drawY, $drawWidth, $drawHeight)
                    } finally {
                        $img.Dispose()
                    }

                    $slotHint = ''
                    if (-not [string]::IsNullOrWhiteSpace($item.LooseSlotNormIds) -and $item.LooseSlotNormIds -ne $item.NormId) {
                        $slotHint = "S:$($item.LooseSlotId)->$($item.LooseSlotNormIds)`n"
                    }
                    $label = "$($item.FileName)`nN:$($item.NormId) $($item.Width)x$($item.Height)`n$slotHint$($item.Status)`n$($item.LastWriteTime)"
                    $graphics.DrawString(
                        $label,
                        $font,
                        $brush,
                        [System.Drawing.RectangleF]::new($x + 4, $y + 104, $cellWidth - 8, $labelHeight)
                    )
                }

                $sheetPath = Join-Path $ReviewDir ('candidate_sheet_{0:d2}.png' -f ($pageIndex + 1))
                $bmp.Save($sheetPath, [System.Drawing.Imaging.ImageFormat]::Png)
                if (-not (Test-Path -LiteralPath $sheetPath)) {
                    throw "Expected output image was not created: $sheetPath"
                }
                $pageCount++
            } finally {
                $graphics.Dispose()
                $bmp.Dispose()
            }
        }
    } finally {
        $font.Dispose()
    }

    return $pageCount
}

function Export-CandidateReport {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo[]]$Files,

        [Parameter(Mandatory = $true)]
        [string]$ReportPath,

        [Parameter(Mandatory = $true)]
        [object]$ManifestIndex
    )

    $rows = foreach ($file in ($Files | Sort-Object LastWriteTime, Name)) {
        $fileNameNoExt = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        $sourceId = $fileNameNoExt.Split('_')[0]
        $normId = Get-NormIdFromSourceId -SourceId $sourceId
        $looseSlotId = Get-LooseSlotId -NormId $normId
        $looseSlotNormIds = ''
        if ($ManifestIndex.LooseSlot.ContainsKey($looseSlotId)) {
            $looseSlotNormIds = (($ManifestIndex.LooseSlot[$looseSlotId] | Sort-Object) -join ',')
        }
        $imageInfo = Get-ImageInfo -FilePath $file.FullName
        $contentHash = Get-FileSha256 -FilePath $file.FullName

        $status = if ($ManifestIndex.ContentHash.ContainsKey($contentHash)) {
            'ExactDuplicate'
        } elseif ($ManifestIndex.NormId.ContainsKey($normId)) {
            'SameNormIdNewContent'
        } elseif ($ManifestIndex.LooseSlot.ContainsKey($looseSlotId)) {
            'SameTail6NewPrefix'
        } else {
            'NewNormId'
        }

        [PSCustomObject]@{
            FileName = $file.Name
            SourceId = $sourceId
            NormId = $normId
            LooseSlotId = $looseSlotId
            LooseSlotNormIds = $looseSlotNormIds
            Width = $imageInfo.Width
            Height = $imageInfo.Height
            Bytes = $file.Length
            LastWriteTime = $file.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')
            Status = $status
            ContentHash = $contentHash
            FullPath = $file.FullName
        }
    }

    $rows | Export-Csv -LiteralPath $ReportPath -NoTypeInformation -Encoding UTF8
    if (-not (Test-Path -LiteralPath $ReportPath)) {
        throw "Expected report was not created: $ReportPath"
    }

    return @($rows)
}

function Invoke-ArchiveCurrentTexCacheBatch {
    param(
        [int]$BatchNumber
    )

    $files = @(Get-ChildItem -LiteralPath $TexCacheDir -File -Filter '*.png' | Sort-Object LastWriteTime, Name)
    if ($files.Count -eq 0) {
        return $false
    }

    if (-not (Test-FilesUnlocked -Files $files)) {
        return $false
    }

    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss_fff'
    $safeTag = ($SessionTag -replace '[\\/:*?"<>|]', '_').Trim()
    if ([string]::IsNullOrWhiteSpace($safeTag)) {
        $safeTag = 'ManualDump'
    }

    $batchDir = Join-Path $OutputRoot ('{0}_{1}_B{2:d4}' -f $stamp, $safeTag, $BatchNumber)
    $rawDir = Join-Path $batchDir 'RawDump'
    $reviewDir = Join-Path $batchDir 'candidate_review'
    $reportPath = Join-Path $batchDir 'candidate_report.csv'

    New-Item -ItemType Directory -Force -Path $rawDir | Out-Null

    foreach ($file in $files) {
        Move-Item -LiteralPath $file.FullName -Destination (Join-Path $rawDir $file.Name)
    }

    $movedFiles = @(Get-ChildItem -LiteralPath $rawDir -File -Filter '*.png' | Sort-Object LastWriteTime, Name)
    $manifestIndex = Import-ManifestIndex -CsvPath $ManifestPath
    $rows = Export-CandidateReport -Files $movedFiles -ReportPath $reportPath -ManifestIndex $manifestIndex
    $sheetCount = New-CandidateSheets -Rows $rows -ReviewDir $reviewDir

    $summary = $rows |
        Group-Object Status |
        ForEach-Object {
            [PSCustomObject]@{
                Status = $_.Name
                Count = $_.Count
            }
        } |
        Sort-Object Status

    $exact = ($summary | Where-Object { $_.Status -eq 'ExactDuplicate' } | Select-Object -First 1).Count
    $newNorm = ($summary | Where-Object { $_.Status -eq 'NewNormId' } | Select-Object -First 1).Count
    $sameTail = ($summary | Where-Object { $_.Status -eq 'SameTail6NewPrefix' } | Select-Object -First 1).Count
    $sameNorm = ($summary | Where-Object { $_.Status -eq 'SameNormIdNewContent' } | Select-Object -First 1).Count
    if ($null -eq $exact) { $exact = 0 }
    if ($null -eq $newNorm) { $newNorm = 0 }
    if ($null -eq $sameTail) { $sameTail = 0 }
    if ($null -eq $sameNorm) { $sameNorm = 0 }

    Write-Host ('[{0}] Batch #{1:d4} archived: {2}' -f (Get-Date -Format 'HH:mm:ss'), $BatchNumber, $batchDir)
    Write-Host ('  Files={0} ExactDuplicate={1} SameNormIdNewContent={2} SameTail6NewPrefix={3} NewNormId={4} Sheets={5}' -f $rows.Count, $exact, $sameNorm, $sameTail, $newNorm, $sheetCount)
    Write-Host ('  Report={0}' -f $reportPath)

    return $true
}

$TexCacheDir = Resolve-WorkspacePath -Path $TexCacheDir -MustExist
$ManifestPath = Resolve-WorkspacePath -Path $ManifestPath -MustExist
$OutputRoot = Resolve-WorkspacePath -Path $OutputRoot
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null

Write-Host "Watching TEXCACHE: $TexCacheDir"
Write-Host "Archive root: $OutputRoot"
Write-Host "Manifest: $ManifestPath"
Write-Host "SessionTag=$SessionTag StableSeconds=$StableSeconds PollMilliseconds=$PollMilliseconds"
Write-Host 'Press Ctrl+C to stop.'

$batchNumber = 1
$lastSignature = ''
$lastChangedAt = [DateTime]::UtcNow

while ($true) {
    $files = @(Get-ChildItem -LiteralPath $TexCacheDir -File -Filter '*.png' | Sort-Object LastWriteTime, Name)
    $signature = Get-TexCacheSignature -Files $files

    if ($signature -ne $lastSignature) {
        $lastSignature = $signature
        $lastChangedAt = [DateTime]::UtcNow
    }

    if ($files.Count -gt 0) {
        $stableForSeconds = ([DateTime]::UtcNow - $lastChangedAt).TotalSeconds
        if ($stableForSeconds -ge $StableSeconds) {
            $processed = Invoke-ArchiveCurrentTexCacheBatch -BatchNumber $batchNumber
            if ($processed) {
                $batchNumber++
                $lastSignature = ''
                $lastChangedAt = [DateTime]::UtcNow
                if ($Once) {
                    break
                }
            }
        }
    } elseif ($Once) {
        Write-Host 'No PNG files found in TEXCACHE. Exit because -Once is set.'
        break
    }

    Start-Sleep -Milliseconds $PollMilliseconds
}
