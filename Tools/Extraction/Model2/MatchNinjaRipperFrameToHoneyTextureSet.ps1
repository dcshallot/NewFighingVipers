param(
    [Parameter(Mandatory = $true)]
    [string]$RipFrameDir,

    [Parameter(Mandatory = $false)]
    [string]$HoneyTextureRoot = "LocalData\Raw\Model2\Honey\Honey_Master_TextureSet",

    [Parameter(Mandatory = $false)]
    [string]$OutputDir = "LocalData\Generated\Model2\NinjaRipperMatches",

    [Parameter(Mandatory = $false)]
    [int]$SampleSize = 16,

    [Parameter(Mandatory = $false)]
    [double]$MinCorrelation = 0.82,

    [Parameter(Mandatory = $false)]
    [int]$TopMatchesPerTexture = 3
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

function Read-CString {
    param([System.IO.BinaryReader]$Reader)

    $bytes = New-Object System.Collections.Generic.List[byte]
    while ($true) {
        $b = $Reader.ReadByte()
        if ($b -eq 0) {
            break
        }
        [void]$bytes.Add($b)
    }

    return [System.Text.Encoding]::ASCII.GetString($bytes.ToArray())
}

function New-ImageProfile {
    param(
        [string]$Name,
        [string]$Category,
        [string]$NormId,
        [int]$Width,
        [int]$Height,
        [double[]]$Samples
    )

    $sum = 0.0
    foreach ($v in $Samples) {
        $sum += $v
    }
    $mean = if ($Samples.Count -gt 0) { $sum / $Samples.Count } else { 0.0 }

    $varSum = 0.0
    foreach ($v in $Samples) {
        $d = $v - $mean
        $varSum += $d * $d
    }
    $std = if ($Samples.Count -gt 0) { [Math]::Sqrt($varSum / $Samples.Count) } else { 0.0 }

    [PSCustomObject]@{
        Name = $Name
        Category = $Category
        NormId = $NormId
        Width = $Width
        Height = $Height
        Samples = $Samples
        Mean = $mean
        Std = $std
    }
}

function Get-BitmapGrayProfile {
    param(
        [string]$ImagePath,
        [string]$Category,
        [string]$NormId,
        [int]$SampleSize
    )

    $bitmap = [System.Drawing.Bitmap]::FromFile($ImagePath)
    try {
        $samples = New-Object double[] ($SampleSize * $SampleSize)
        for ($sy = 0; $sy -lt $SampleSize; $sy++) {
            $srcY = [int][Math]::Floor((($sy + 0.5) * $bitmap.Height / $SampleSize))
            if ($srcY -ge $bitmap.Height) { $srcY = $bitmap.Height - 1 }

            for ($sx = 0; $sx -lt $SampleSize; $sx++) {
                $srcX = [int][Math]::Floor((($sx + 0.5) * $bitmap.Width / $SampleSize))
                if ($srcX -ge $bitmap.Width) { $srcX = $bitmap.Width - 1 }

                $color = $bitmap.GetPixel($srcX, $srcY)
                $samples[$sy * $SampleSize + $sx] = (0.299 * $color.R) + (0.587 * $color.G) + (0.114 * $color.B)
            }
        }

        return New-ImageProfile -Name (Split-Path -Leaf $ImagePath) -Category $Category -NormId $NormId -Width $bitmap.Width -Height $bitmap.Height -Samples $samples
    }
    finally {
        $bitmap.Dispose()
    }
}

function Get-DdsGrayProfile {
    param(
        [string]$ImagePath,
        [int]$SampleSize
    )

    $bytes = [System.IO.File]::ReadAllBytes($ImagePath)
    if ($bytes.Length -lt 128) {
        throw "DDS too small: $ImagePath"
    }

    $magic = [System.Text.Encoding]::ASCII.GetString($bytes, 0, 4)
    if ($magic -ne "DDS ") {
        throw "Not a DDS file: $ImagePath"
    }

    $height = [int][BitConverter]::ToUInt32($bytes, 12)
    $width = [int][BitConverter]::ToUInt32($bytes, 16)
    $pixelFormatFlags = [BitConverter]::ToUInt32($bytes, 80)
    $fourCCValue = [BitConverter]::ToUInt32($bytes, 84)
    $rgbBitCount = [int][BitConverter]::ToUInt32($bytes, 88)
    $rMask = [BitConverter]::ToUInt32($bytes, 92)
    $gMask = [BitConverter]::ToUInt32($bytes, 96)
    $bMask = [BitConverter]::ToUInt32($bytes, 100)
    $aMask = [BitConverter]::ToUInt32($bytes, 104)

    if ($fourCCValue -ne [UInt32]0 -or $rgbBitCount -ne 32 -or $rMask -ne [UInt32]16711680 -or $gMask -ne [UInt32]65280 -or $bMask -ne [UInt32]255 -or $aMask -ne [UInt32]4278190080) {
        $fourCCText = [System.Text.Encoding]::ASCII.GetString($bytes, 84, 4).Replace("`0", ".")
        throw "Unsupported DDS format in $ImagePath (Flags=$pixelFormatFlags FourCCValue=$fourCCValue FourCC=$fourCCText RGBBitCount=$rgbBitCount Masks=$rMask/$gMask/$bMask/$aMask)"
    }

    $expectedLength = 128 + ($width * $height * 4)
    if ($bytes.Length -lt $expectedLength) {
        throw "DDS payload shorter than expected: $ImagePath"
    }

    $samples = New-Object double[] ($SampleSize * $SampleSize)
    for ($sy = 0; $sy -lt $SampleSize; $sy++) {
        $srcY = [int][Math]::Floor((($sy + 0.5) * $height / $SampleSize))
        if ($srcY -ge $height) { $srcY = $height - 1 }

        for ($sx = 0; $sx -lt $SampleSize; $sx++) {
            $srcX = [int][Math]::Floor((($sx + 0.5) * $width / $SampleSize))
            if ($srcX -ge $width) { $srcX = $width - 1 }

            $pixelOffset = 128 + (($srcY * $width + $srcX) * 4)
            $b = $bytes[$pixelOffset + 0]
            $g = $bytes[$pixelOffset + 1]
            $r = $bytes[$pixelOffset + 2]
            $samples[$sy * $SampleSize + $sx] = (0.299 * $r) + (0.587 * $g) + (0.114 * $b)
        }
    }

    return New-ImageProfile -Name (Split-Path -Leaf $ImagePath) -Category "" -NormId "" -Width $width -Height $height -Samples $samples
}

function Get-TransformedIndex {
    param(
        [string]$Transform,
        [int]$X,
        [int]$Y,
        [int]$SampleSize
    )

    switch ($Transform) {
        "Identity" { $tx = $X; $ty = $Y }
        "FlipX" { $tx = $SampleSize - 1 - $X; $ty = $Y }
        "FlipY" { $tx = $X; $ty = $SampleSize - 1 - $Y }
        "FlipXY" { $tx = $SampleSize - 1 - $X; $ty = $SampleSize - 1 - $Y }
        "Transpose" { $tx = $Y; $ty = $X }
        "TransposeFlipX" { $tx = $SampleSize - 1 - $Y; $ty = $X }
        "TransposeFlipY" { $tx = $Y; $ty = $SampleSize - 1 - $X }
        "TransposeFlipXY" { $tx = $SampleSize - 1 - $Y; $ty = $SampleSize - 1 - $X }
        default { throw "Unknown transform: $Transform" }
    }

    return $ty * $SampleSize + $tx
}

function Compare-ImageProfiles {
    param(
        [object]$Candidate,
        [object]$Reference,
        [string]$Transform,
        [int]$SampleSize
    )

    $sameOrientation = ($Transform -like "Transpose*") -eq $false
    if ($sameOrientation) {
        if ($Candidate.Width -ne $Reference.Width -or $Candidate.Height -ne $Reference.Height) {
            return $null
        }
    }
    else {
        if ($Candidate.Width -ne $Reference.Height -or $Candidate.Height -ne $Reference.Width) {
            return $null
        }
    }

    $mse = 0.0
    $dot = 0.0

    for ($i = 0; $i -lt $Candidate.Samples.Count; $i++) {
        $x = $i % $SampleSize
        $y = [int][Math]::Floor($i / $SampleSize)
        $refIndex = Get-TransformedIndex -Transform $Transform -X $x -Y $y -SampleSize $SampleSize

        $a = $Candidate.Samples[$i]
        $b = $Reference.Samples[$refIndex]

        $d = $a - $b
        $mse += $d * $d

        $dot += ($a - $Candidate.Mean) * ($b - $Reference.Mean)
    }

    $n = [double]$Candidate.Samples.Count
    $rmse = [Math]::Sqrt($mse / $n)
    $corr = 0.0
    if ($Candidate.Std -gt 0.00001 -and $Reference.Std -gt 0.00001) {
        $corr = $dot / ($n * $Candidate.Std * $Reference.Std)
    }
    elseif ($Candidate.Std -le 0.00001 -and $Reference.Std -le 0.00001) {
        $corr = 1.0 - [Math]::Min(1.0, [Math]::Abs($Candidate.Mean - $Reference.Mean) / 255.0)
    }

    [PSCustomObject]@{
        Transform = $Transform
        Correlation = [Math]::Round($corr, 6)
        Rmse = [Math]::Round($rmse, 6)
    }
}

function Get-BestTextureMatches {
    param(
        [object]$DdsProfile,
        [object[]]$ReferenceProfiles,
        [int]$SampleSize,
        [int]$TopMatches
    )

    $transformNames = @(
        "Identity",
        "FlipX",
        "FlipY",
        "FlipXY",
        "Transpose",
        "TransposeFlipX",
        "TransposeFlipY",
        "TransposeFlipXY"
    )

    $matches = New-Object System.Collections.Generic.List[object]
    foreach ($reference in $ReferenceProfiles) {
        foreach ($transform in $transformNames) {
            $score = Compare-ImageProfiles -Candidate $DdsProfile -Reference $reference -Transform $transform -SampleSize $SampleSize
            if ($null -eq $score) {
                continue
            }

            [void]$matches.Add([PSCustomObject]@{
                DdsName = $DdsProfile.Name
                DdsSize = "$($DdsProfile.Width)x$($DdsProfile.Height)"
                HoneyCategory = $reference.Category
                HoneyNormId = $reference.NormId
                HoneyPng = $reference.Name
                HoneySize = "$($reference.Width)x$($reference.Height)"
                Transform = $score.Transform
                Correlation = $score.Correlation
                Rmse = $score.Rmse
            })
        }
    }

    return $matches |
        Sort-Object -Property @{ Expression = 'Correlation'; Descending = $true }, @{ Expression = 'Rmse'; Descending = $false } |
        Select-Object -First $TopMatches
}

function Parse-RipMeshInfo {
    param([string]$RipPath)

    $fs = [System.IO.File]::OpenRead($RipPath)
    $reader = New-Object System.IO.BinaryReader($fs)
    try {
        [void]$reader.ReadUInt32()
        [void]$reader.ReadUInt32()
        $numFaces = [int]$reader.ReadUInt32()
        $numVerts = [int]$reader.ReadUInt32()
        $blockSize = [int]$reader.ReadUInt32()
        $textureFilesCnt = [int]$reader.ReadUInt32()
        $shaderFilesCnt = [int]$reader.ReadUInt32()
        $vertexAttributesCnt = [int]$reader.ReadUInt32()

        $posOffset = 0
        $hasPos = $false
        $attribs = New-Object System.Collections.Generic.List[string]

        for ($i = 0; $i -lt $vertexAttributesCnt; $i++) {
            $semantic = Read-CString -Reader $reader
            $semanticIndex = [int]$reader.ReadUInt32()
            $offset = [int]$reader.ReadUInt32()
            $size = [int]$reader.ReadUInt32()
            $typeMapElements = [int]$reader.ReadUInt32()
            if ($typeMapElements -gt 0) {
                [void]$reader.ReadBytes($typeMapElements * 4)
            }

            [void]$attribs.Add("$semantic$semanticIndex@$offset/$size")
            if (-not $hasPos -and $semantic -eq "POSITION") {
                $hasPos = $true
                $posOffset = $offset
            }
        }

        $textures = New-Object System.Collections.Generic.List[string]
        for ($i = 0; $i -lt $textureFilesCnt; $i++) {
            [void]$textures.Add((Read-CString -Reader $reader))
        }
        for ($i = 0; $i -lt $shaderFilesCnt; $i++) {
            [void](Read-CString -Reader $reader)
        }

        $numIdx = $numFaces * 3
        if ($numIdx -gt 0) {
            [void]$reader.ReadBytes($numIdx * 4)
        }

        $minX = [double]::PositiveInfinity
        $minY = [double]::PositiveInfinity
        $minZ = [double]::PositiveInfinity
        $maxX = [double]::NegativeInfinity
        $maxY = [double]::NegativeInfinity
        $maxZ = [double]::NegativeInfinity

        if ($hasPos -and $blockSize -ge ($posOffset + 12)) {
            for ($v = 0; $v -le $numVerts; $v++) {
                $vertexBytes = $reader.ReadBytes($blockSize)
                if ($vertexBytes.Length -lt $blockSize) {
                    break
                }

                $x = [BitConverter]::ToSingle($vertexBytes, $posOffset)
                $y = [BitConverter]::ToSingle($vertexBytes, $posOffset + 4)
                $z = [BitConverter]::ToSingle($vertexBytes, $posOffset + 8)

                if ($x -lt $minX) { $minX = $x }
                if ($x -gt $maxX) { $maxX = $x }
                if ($y -lt $minY) { $minY = $y }
                if ($y -gt $maxY) { $maxY = $y }
                if ($z -lt $minZ) { $minZ = $z }
                if ($z -gt $maxZ) { $maxZ = $z }
            }
        }

        $extentX = if ([double]::IsInfinity($minX)) { 0.0 } else { $maxX - $minX }
        $extentY = if ([double]::IsInfinity($minY)) { 0.0 } else { $maxY - $minY }
        $extentZ = if ([double]::IsInfinity($minZ)) { 0.0 } else { $maxZ - $minZ }
        $maxExtent = [Math]::Max($extentX, [Math]::Max($extentY, $extentZ))
        $minExtent = [Math]::Min($extentX, [Math]::Min($extentY, $extentZ))
        $thinness = if ($maxExtent -gt 0) { $minExtent / $maxExtent } else { 0.0 }

        [PSCustomObject]@{
            MeshName = Split-Path -Leaf $RipPath
            NumFaces = $numFaces
            NumVerts = $numVerts
            BlockSize = $blockSize
            Textures = ($textures -join ';')
            Attribs = ($attribs -join ';')
            ExtentX = [Math]::Round($extentX, 6)
            ExtentY = [Math]::Round($extentY, 6)
            ExtentZ = [Math]::Round($extentZ, 6)
            SumExtent = [Math]::Round($extentX + $extentY + $extentZ, 6)
            Thinness = [Math]::Round($thinness, 6)
        }
    }
    finally {
        $reader.Dispose()
        $fs.Dispose()
    }
}

$ripFrameDirPath = Resolve-RepoPath -PathValue $RipFrameDir
$honeyRootPath = Resolve-RepoPath -PathValue $HoneyTextureRoot
$outputDirPath = if ([System.IO.Path]::IsPathRooted($OutputDir)) { [System.IO.Path]::GetFullPath($OutputDir) } else { [System.IO.Path]::GetFullPath((Join-Path $repoRoot $OutputDir)) }
$localDataRoot = [System.IO.Path]::GetFullPath((Join-Path $repoRoot "LocalData")).TrimEnd([char[]]@('\', '/'))
if (-not $outputDirPath.StartsWith($localDataRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) { throw "OutputDir must stay under LocalData" }
[void](New-Item -ItemType Directory -Path $outputDirPath -Force)

$referenceProfiles = New-Object System.Collections.Generic.List[object]
foreach ($categoryName in @("Main", "ColorAlt_P2")) {
    $categoryRoot = Join-Path $honeyRootPath $categoryName
    if (-not (Test-Path -LiteralPath $categoryRoot)) {
        continue
    }

    foreach ($pngFile in Get-ChildItem -Path $categoryRoot -Recurse -File -Filter "*.png") {
        $normId = ($pngFile.BaseName -split "_")[0]
        if ($normId -match "^[0-9A-Fa-f]{7,8}$" -eq $false -and $pngFile.BaseName -match "([0-9A-Fa-f]{7,8})") {
            $normId = $Matches[1]
        }
        $assetCategory = Split-Path -Leaf (Split-Path -Parent $pngFile.FullName)
        [void]$referenceProfiles.Add((Get-BitmapGrayProfile -ImagePath $pngFile.FullName -Category "$categoryName/$assetCategory" -NormId $normId -SampleSize $SampleSize))
    }
}

if ($referenceProfiles.Count -eq 0) {
    throw "No Honey reference textures found under $honeyRootPath"
}

$ddsProfiles = @{}
$textureMatchRows = New-Object System.Collections.Generic.List[object]

foreach ($ddsFile in Get-ChildItem -LiteralPath $ripFrameDirPath -File -Filter "*.dds") {
    $ddsProfile = Get-DdsGrayProfile -ImagePath $ddsFile.FullName -SampleSize $SampleSize
    $ddsProfiles[$ddsProfile.Name] = $ddsProfile

    $bestMatches = Get-BestTextureMatches -DdsProfile $ddsProfile -ReferenceProfiles $referenceProfiles -SampleSize $SampleSize -TopMatches $TopMatchesPerTexture
    foreach ($match in $bestMatches) {
        [void]$textureMatchRows.Add($match)
    }
}

$textureMatchCsv = Join-Path $outputDirPath "_texture_honey_match_candidates.csv"
$textureMatchRows |
    Sort-Object -Property @{ Expression = 'Correlation'; Descending = $true }, @{ Expression = 'Rmse'; Descending = $false } |
    Export-Csv -LiteralPath $textureMatchCsv -NoTypeInformation -Encoding UTF8

$bestTextureMatchByDds = @{}
foreach ($group in ($textureMatchRows | Group-Object DdsName)) {
    $bestTextureMatchByDds[$group.Name] = $group.Group |
        Sort-Object -Property @{ Expression = 'Correlation'; Descending = $true }, @{ Expression = 'Rmse'; Descending = $false } |
        Select-Object -First 1
}

$meshRows = New-Object System.Collections.Generic.List[object]
foreach ($ripFile in Get-ChildItem -LiteralPath $ripFrameDirPath -File -Filter "*.rip") {
    $meshInfo = Parse-RipMeshInfo -RipPath $ripFile.FullName

    $meshTextures = @()
    if ($meshInfo.Textures) {
        $meshTextures = $meshInfo.Textures -split ';'
    }

    $meshBestMatch = $null
    foreach ($textureName in $meshTextures) {
        if ($bestTextureMatchByDds.ContainsKey($textureName) -eq $false) {
            continue
        }

        $candidate = $bestTextureMatchByDds[$textureName]
        if ($null -eq $meshBestMatch -or $candidate.Correlation -gt $meshBestMatch.Correlation -or ($candidate.Correlation -eq $meshBestMatch.Correlation -and $candidate.Rmse -lt $meshBestMatch.Rmse)) {
            $meshBestMatch = $candidate
        }
    }

    $meshCorrelation = if ($null -eq $meshBestMatch) { 0.0 } else { [double]$meshBestMatch.Correlation }
    $meshRmse = if ($null -eq $meshBestMatch) { 999999.0 } else { [double]$meshBestMatch.Rmse }

    [void]$meshRows.Add([PSCustomObject]@{
        MeshName = $meshInfo.MeshName
        NumFaces = $meshInfo.NumFaces
        NumVerts = $meshInfo.NumVerts
        SumExtent = $meshInfo.SumExtent
        ExtentX = $meshInfo.ExtentX
        ExtentY = $meshInfo.ExtentY
        ExtentZ = $meshInfo.ExtentZ
        Thinness = $meshInfo.Thinness
        MeshTextures = $meshInfo.Textures
        BestMatchedDds = if ($null -eq $meshBestMatch) { "" } else { $meshBestMatch.DdsName }
        BestHoneyCategory = if ($null -eq $meshBestMatch) { "" } else { $meshBestMatch.HoneyCategory }
        BestHoneyNormId = if ($null -eq $meshBestMatch) { "" } else { $meshBestMatch.HoneyNormId }
        BestHoneyPng = if ($null -eq $meshBestMatch) { "" } else { $meshBestMatch.HoneyPng }
        BestTransform = if ($null -eq $meshBestMatch) { "" } else { $meshBestMatch.Transform }
        Correlation = [Math]::Round($meshCorrelation, 6)
        Rmse = [Math]::Round($meshRmse, 6)
        IsLikelyHoneyTexture = ($meshCorrelation -ge $MinCorrelation)
    })
}

$meshMatchCsv = Join-Path $outputDirPath "_mesh_honey_match_candidates.csv"
$meshRows |
    Sort-Object -Property @{ Expression = 'IsLikelyHoneyTexture'; Descending = $true }, @{ Expression = 'Correlation'; Descending = $true }, @{ Expression = 'NumFaces'; Descending = $true } |
    Export-Csv -LiteralPath $meshMatchCsv -NoTypeInformation -Encoding UTF8

Write-Host "Wrote texture matches: $textureMatchCsv"
Write-Host "Wrote mesh matches:    $meshMatchCsv"
Write-Host ""
Write-Host "Top likely Honey mesh candidates:"
$meshRows |
    Where-Object { $_.IsLikelyHoneyTexture } |
    Sort-Object -Property @{ Expression = 'Correlation'; Descending = $true }, @{ Expression = 'NumFaces'; Descending = $true } |
    Select-Object -First 80 MeshName,NumFaces,NumVerts,SumExtent,Thinness,BestMatchedDds,BestHoneyCategory,BestHoneyNormId,BestHoneyPng,BestTransform,Correlation,Rmse |
    Format-Table -AutoSize |
    Out-String -Width 500 |
    Write-Host
