param(
    [string]$Dk2Path = $env:DK2_PATH,
    [string]$OpenKeeperDir = (Join-Path (Resolve-Path -LiteralPath "$PSScriptRoot\..\..").Path 'LocalData\ThirdParty\OpenKeeper'),
    [switch]$NoClone,
    [switch]$NoRun
)

$ErrorActionPreference = 'Stop'

function Get-JavaMajorVersion {
    $java = Get-Command java -ErrorAction SilentlyContinue
    if (-not $java) {
        return $null
    }

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & java -version 2>&1
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    $versionLine = ($output | Select-Object -First 1).ToString()
    if ($versionLine -match '"(?<version>\d+)(?:\.|")') {
        return [int]$Matches.version
    }

    return $null
}

if ([string]::IsNullOrWhiteSpace($Dk2Path)) {
    throw "Specify -Dk2Path or set the DK2_PATH environment variable."
}

$dk2FullPath = [System.IO.Path]::GetFullPath($Dk2Path)
if (-not (Test-Path -LiteralPath $dk2FullPath -PathType Container)) {
    throw "Dungeon Keeper 2 folder not found: $dk2FullPath"
}

$frontEndLevel = Join-Path $dk2FullPath 'Data\editor\maps\FrontEnd3DLevel.kwd'
if (-not (Test-Path -LiteralPath $frontEndLevel -PathType Leaf)) {
    throw "DK2 install does not look valid for OpenKeeper. Missing: $frontEndLevel"
}

$javaMajor = Get-JavaMajorVersion
if ($null -eq $javaMajor -or $javaMajor -lt 25) {
    throw "OpenKeeper master currently requires Java JDK 25+. Install JDK 25 and make sure java is available on PATH."
}

if (-not (Get-Command javac -ErrorAction SilentlyContinue)) {
    throw "OpenKeeper needs a JDK, not just a JRE. Install JDK 25 and make sure javac is available on PATH."
}

$openKeeperFullPath = [System.IO.Path]::GetFullPath($OpenKeeperDir)
if (-not (Test-Path -LiteralPath $openKeeperFullPath -PathType Container)) {
    if ($NoClone) {
        throw "OpenKeeper checkout not found and -NoClone was specified: $openKeeperFullPath"
    }

    $parent = Split-Path -Parent $openKeeperFullPath
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    git clone https://github.com/tonihele/OpenKeeper.git $openKeeperFullPath
}

$gradlew = Join-Path $openKeeperFullPath 'gradlew.bat'
if (-not (Test-Path -LiteralPath $gradlew -PathType Leaf)) {
    throw "OpenKeeper checkout is missing gradlew.bat: $gradlew"
}

$settingsPath = Join-Path $openKeeperFullPath 'openkeeper.properties'
$dk2SettingsPath = $dk2FullPath
if (-not $dk2SettingsPath.EndsWith('\')) {
    $dk2SettingsPath = "$dk2SettingsPath\"
}
$escapedDk2SettingsPath = $dk2SettingsPath.Replace('\', '\\').Replace(':', '\:')
$dk2SettingsLine = "DungeonKeeperIIFolder(string)=$escapedDk2SettingsPath"

if (Test-Path -LiteralPath $settingsPath -PathType Leaf) {
    $settingsLines = @(Get-Content -LiteralPath $settingsPath -Encoding UTF8)
    $updatedSettingsLines = @()
    $updatedDk2Path = $false
    foreach ($line in $settingsLines) {
        if ($line -match '^DungeonKeeperIIFolder\(string\)=') {
            $updatedSettingsLines += $dk2SettingsLine
            $updatedDk2Path = $true
        } else {
            $updatedSettingsLines += $line
        }
    }
    if (-not $updatedDk2Path) {
        $updatedSettingsLines += $dk2SettingsLine
    }
    [System.IO.File]::WriteAllLines($settingsPath, $updatedSettingsLines, [System.Text.UTF8Encoding]::new($false))
} else {
    [System.IO.File]::WriteAllLines($settingsPath, @('#jME3 AppSettings', $dk2SettingsLine), [System.Text.UTF8Encoding]::new($false))
}

Write-Host "OpenKeeper checkout: $openKeeperFullPath"
Write-Host "Dungeon Keeper 2 assets: $dk2FullPath"
Write-Host "Settings written: $settingsPath"

if (-not $NoRun) {
    Push-Location $openKeeperFullPath
    try {
        & $gradlew run
    } finally {
        Pop-Location
    }
}
