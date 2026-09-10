param(
    [Parameter(Mandatory = $true)]
    [string]$RipFrameDir,

    [Parameter(Mandatory = $true)]
    [string]$TextureName,

    [Parameter(Mandatory = $false)]
    [string]$OutputObjPath = "",

    [Parameter(Mandatory = $false)]
    [switch]$PerspectiveDivideByW,

    [Parameter(Mandatory = $false)]
    [switch]$FlipV
)

$ErrorActionPreference = "Stop"
$InvariantCulture = [System.Globalization.CultureInfo]::InvariantCulture
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

function Format-ObjFloat {
    param([double]$Value)

    return $Value.ToString("0.#########", $InvariantCulture)
}

function Read-RipMesh {
    param(
        [string]$RipPath,
        [string]$RequiredTextureName = ""
    )

    $fs = [System.IO.File]::OpenRead($RipPath)
    $reader = New-Object System.IO.BinaryReader($fs)
    try {
        $magic = $reader.ReadUInt32()
        if ($magic -ne [UInt32]3735929054) {
            throw "Not a Ninja Ripper mesh: $RipPath"
        }

        $version = $reader.ReadUInt32()
        if ($version -ne [UInt32]4) {
            throw "Unsupported Ninja Ripper version $version in $RipPath"
        }

        $numFaces = [int]$reader.ReadUInt32()
        $numVerts = [int]$reader.ReadUInt32()
        $blockSize = [int]$reader.ReadUInt32()
        $textureFilesCnt = [int]$reader.ReadUInt32()
        $shaderFilesCnt = [int]$reader.ReadUInt32()
        $vertexAttributesCnt = [int]$reader.ReadUInt32()

        $posOffset = -1
        $uvOffset = -1

        for ($i = 0; $i -lt $vertexAttributesCnt; $i++) {
            $semantic = Read-CString -Reader $reader
            $semanticIndex = [int]$reader.ReadUInt32()
            $offset = [int]$reader.ReadUInt32()
            [void]$reader.ReadUInt32() # size
            $typeMapElements = [int]$reader.ReadUInt32()
            if ($typeMapElements -gt 0) {
                [void]$reader.ReadBytes($typeMapElements * 4)
            }

            if ($semantic -eq "POSITION" -and $semanticIndex -eq 0 -and $posOffset -lt 0) {
                $posOffset = $offset
            }
            elseif ($semantic -eq "TEXCOORD" -and $semanticIndex -eq 0 -and $uvOffset -lt 0) {
                $uvOffset = $offset
            }
        }

        $textures = New-Object System.Collections.Generic.List[string]
        for ($i = 0; $i -lt $textureFilesCnt; $i++) {
            [void]$textures.Add((Read-CString -Reader $reader))
        }

        for ($i = 0; $i -lt $shaderFilesCnt; $i++) {
            [void](Read-CString -Reader $reader)
        }

        if (-not [string]::IsNullOrWhiteSpace($RequiredTextureName) -and $textures -notcontains $RequiredTextureName) {
            return [PSCustomObject]@{
                MeshName = [System.IO.Path]::GetFileNameWithoutExtension($RipPath)
                TextureFiles = $textures
                Positions = @()
                Uvs = @()
                Indices = @()
            }
        }

        $numIdx = $numFaces * 3
        $indices = New-Object UInt32[] $numIdx
        for ($i = 0; $i -lt $numIdx; $i++) {
            $indices[$i] = $reader.ReadUInt32()
        }

        $vertexCount = $numVerts
        $positions = New-Object System.Collections.Generic.List[double[]]
        $uvs = New-Object System.Collections.Generic.List[double[]]

        for ($i = 0; $i -lt $vertexCount; $i++) {
            $vertexBytes = $reader.ReadBytes($blockSize)
            if ($vertexBytes.Length -ne $blockSize) {
                throw "Unexpected EOF while reading vertex $i in $RipPath"
            }

            $x = 0.0
            $y = 0.0
            $z = 0.0
            if ($posOffset -ge 0 -and $blockSize -ge ($posOffset + 12)) {
                $x = [BitConverter]::ToSingle($vertexBytes, $posOffset)
                $y = [BitConverter]::ToSingle($vertexBytes, $posOffset + 4)
                $z = [BitConverter]::ToSingle($vertexBytes, $posOffset + 8)

                if ($PerspectiveDivideByW -and $blockSize -ge ($posOffset + 16)) {
                    $w = [BitConverter]::ToSingle($vertexBytes, $posOffset + 12)
                    if ([Math]::Abs($w) -gt 0.000001) {
                        $x /= $w
                        $y /= $w
                        $z /= $w
                    }
                }
            }

            $u = 0.0
            $v = 0.0
            if ($uvOffset -ge 0 -and $blockSize -ge ($uvOffset + 8)) {
                $u = [BitConverter]::ToSingle($vertexBytes, $uvOffset)
                $v = [BitConverter]::ToSingle($vertexBytes, $uvOffset + 4)
                if ($FlipV) {
                    $v = 1.0 - $v
                }
            }

            [void]$positions.Add(@($x, $y, $z))
            [void]$uvs.Add(@($u, $v))
        }

        return [PSCustomObject]@{
            MeshName = [System.IO.Path]::GetFileNameWithoutExtension($RipPath)
            TextureFiles = $textures
            Positions = $positions
            Uvs = $uvs
            Indices = $indices
        }
    }
    finally {
        $reader.Dispose()
        $fs.Dispose()
    }
}

$ripFrameDirPath = Resolve-RepoPath -PathValue $RipFrameDir
if ([string]::IsNullOrWhiteSpace($OutputObjPath)) {
    $textureBaseName = [System.IO.Path]::GetFileNameWithoutExtension($TextureName)
    $suffix = if ($PerspectiveDivideByW) { "_pwdiv" } else { "_raw" }
    $OutputObjPath = Join-Path $repoRoot ("LocalData\Generated\Model2\MergedMeshes\_merged_{0}{1}.obj" -f $textureBaseName, $suffix)
}
elseif (-not [System.IO.Path]::IsPathRooted($OutputObjPath)) {
    $OutputObjPath = Join-Path $repoRoot $OutputObjPath
}

$outputObjFullPath = [System.IO.Path]::GetFullPath($OutputObjPath)
$localDataRoot = [System.IO.Path]::GetFullPath((Join-Path $repoRoot "LocalData")).TrimEnd([char[]]@('\', '/'))
if (-not $outputObjFullPath.StartsWith($localDataRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) { throw "OutputObjPath must stay under LocalData" }
$outputDir = [System.IO.Path]::GetDirectoryName($outputObjFullPath)
if (-not (Test-Path -LiteralPath $outputDir)) {
    [void](New-Item -ItemType Directory -Path $outputDir)
}

$mtlName = [System.IO.Path]::GetFileNameWithoutExtension($outputObjFullPath) + ".mtl"
$outputMtlFullPath = Join-Path $outputDir $mtlName

$ripFiles = Get-ChildItem -LiteralPath $ripFrameDirPath -Filter '*.rip' -File | Sort-Object Name
$matchedMeshes = New-Object System.Collections.Generic.List[object]
$skippedMeshes = New-Object System.Collections.Generic.List[string]
foreach ($ripFile in $ripFiles) {
    try {
        $mesh = Read-RipMesh -RipPath $ripFile.FullName -RequiredTextureName $TextureName
        if ($mesh.TextureFiles -contains $TextureName) {
            [void]$matchedMeshes.Add($mesh)
        }
    }
    catch {
        [void]$skippedMeshes.Add(("{0}: {1}" -f $ripFile.Name, $_.Exception.Message))
    }
}

if ($matchedMeshes.Count -eq 0) {
    throw "No .rip mesh references texture '$TextureName' under $ripFrameDirPath"
}

$writer = New-Object System.IO.StreamWriter($outputObjFullPath, $false, [System.Text.Encoding]::ASCII)
try {
    $materialName = "mat_" + ([System.IO.Path]::GetFileNameWithoutExtension($TextureName) -replace '[^A-Za-z0-9_]+', '_')
    $writer.WriteLine("# merged by MergeNinjaRipperMeshesByTexture.ps1")
    $writer.WriteLine("# source frame: {0}" -f $ripFrameDirPath)
    $writer.WriteLine("# source texture: {0}" -f $TextureName)
    $writer.WriteLine("# mesh count: {0}" -f $matchedMeshes.Count)
    $writer.WriteLine("mtllib {0}" -f $mtlName)
    $writer.WriteLine("usemtl {0}" -f $materialName)

    $vertexOffset = 0
    foreach ($mesh in $matchedMeshes) {
        $writer.WriteLine("")
        $writer.WriteLine("o {0}" -f $mesh.MeshName)
        $writer.WriteLine("g {0}" -f $mesh.MeshName)

        foreach ($position in $mesh.Positions) {
            $vertexLine = "v {0} {1} {2}" -f (Format-ObjFloat -Value $position[0]), (Format-ObjFloat -Value $position[1]), (Format-ObjFloat -Value $position[2])
            $writer.WriteLine($vertexLine)
        }

        foreach ($uv in $mesh.Uvs) {
            $uvLine = "vt {0} {1}" -f (Format-ObjFloat -Value $uv[0]), (Format-ObjFloat -Value $uv[1])
            $writer.WriteLine($uvLine)
        }

        for ($i = 0; $i -lt $mesh.Indices.Count; $i += 3) {
            $a = $vertexOffset + [int]$mesh.Indices[$i + 0] + 1
            $b = $vertexOffset + [int]$mesh.Indices[$i + 1] + 1
            $c = $vertexOffset + [int]$mesh.Indices[$i + 2] + 1
            $faceLine = "f {0}/{0} {1}/{1} {2}/{2}" -f $a, $b, $c
            $writer.WriteLine($faceLine)
        }

        $vertexOffset += $mesh.Positions.Count
    }
}
finally {
    $writer.Dispose()
}

$materialName = "mat_" + ([System.IO.Path]::GetFileNameWithoutExtension($TextureName) -replace '[^A-Za-z0-9_]+', '_')
$mtlWriter = New-Object System.IO.StreamWriter($outputMtlFullPath, $false, [System.Text.Encoding]::ASCII)
try {
    $mtlWriter.WriteLine("newmtl {0}" -f $materialName)
    $mtlWriter.WriteLine("Kd 1.000000 1.000000 1.000000")
    $mtlWriter.WriteLine("Ka 0.000000 0.000000 0.000000")
    $mtlWriter.WriteLine("Ks 0.000000 0.000000 0.000000")
    $mtlWriter.WriteLine("d 1.000000")
    $mtlWriter.WriteLine("illum 1")
    $mtlWriter.WriteLine("map_Kd {0}" -f $TextureName)
}
finally {
    $mtlWriter.Dispose()
}

[PSCustomObject]@{
    OutputObj = $outputObjFullPath
    OutputMtl = $outputMtlFullPath
    TextureName = $TextureName
    MeshCount = $matchedMeshes.Count
    SkippedMeshCount = $skippedMeshes.Count
    SkippedMeshes = ($skippedMeshes -join ';')
    MeshNames = (($matchedMeshes | ForEach-Object { $_.MeshName }) -join ';')
} | Format-List *
