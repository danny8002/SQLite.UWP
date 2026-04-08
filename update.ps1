$ErrorActionPreference = 'Stop'

# Paths
$repoRoot     = $PSScriptRoot
$sourceDir    = Join-Path $repoRoot 'SQLite.Universal\SourceCode'
$nuspecPath   = Join-Path $repoRoot 'NuGet\package.nuspec'
$rcHeaderPath = Join-Path $sourceDir 'sqlite3rc.h'
$downloadPage = 'https://www.sqlite.org/download.html'
$baseUrl      = 'https://www.sqlite.org'

# Step 1: Download and parse the SQLite download page
Write-Host 'Downloading SQLite download page...'
$response = Invoke-WebRequest -Uri $downloadPage -UseBasicParsing
$html = $response.Content

# Extract version from page text (e.g., "SQLite version 3.51.3")
if ($html -match 'SQLite version (\d+\.\d+\.\d+)') {
    $newVersion = $Matches[1]
    Write-Host "Latest SQLite version: $newVersion"
} else {
    throw 'Could not parse SQLite version from download page.'
}

# Extract real download URL from JavaScript block
# The page uses JS obfuscation: d391('a2','2026/sqlite-amalgamation-3510300.zip')
# We match the path pattern directly to be robust against function name changes
if ($html -match "'(\d{4}/sqlite-amalgamation-\d{7}\.zip)'") {
    $relativePath = $Matches[1]
    $zipUrl = "$baseUrl/$relativePath"
    Write-Host "Download URL: $zipUrl"
} else {
    throw 'Could not find amalgamation download link on page.'
}

# Check current version
$currentNuspecContent = Get-Content $nuspecPath -Raw
if ($currentNuspecContent -match '<version>(\d+\.\d+\.\d+)</version>') {
    $currentVersion = $Matches[1]
} else {
    $currentVersion = 'unknown'
}

if ($currentVersion -eq $newVersion) {
    Write-Host "Already at version $newVersion. No update needed."
    exit 0
}
Write-Host "Updating from $currentVersion to $newVersion..."

# Step 2: Download and extract the amalgamation zip
$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "sqlite-update-$([System.Guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
$zipPath = Join-Path $tempDir 'sqlite-amalgamation.zip'

try {
    Write-Host 'Downloading amalgamation zip...'
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing

    Write-Host 'Extracting...'
    Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force

    $extractedDir = Get-ChildItem -Path $tempDir -Directory |
                    Where-Object { $_.Name -like 'sqlite-amalgamation-*' } |
                    Select-Object -First 1

    if (-not $extractedDir) {
        throw 'Could not find extracted amalgamation directory.'
    }

    # Step 3: Replace source files
    $filesToCopy = @('sqlite3.c', 'sqlite3.h', 'sqlite3ext.h')
    foreach ($file in $filesToCopy) {
        $src = Join-Path $extractedDir.FullName $file
        $dst = Join-Path $sourceDir $file
        if (-not (Test-Path $src)) {
            throw "Expected file not found in amalgamation: $file"
        }
        Copy-Item -Path $src -Destination $dst -Force
        Write-Host "  Replaced $file"
    }

    # Step 4: Patch sqlite3.c for UWP compatibility
    # GetModuleHandleW is not available in UWP (WINAPI_FAMILY_APP), guard with additional check
    # See: https://github.com/danny8002/SQLite3.Universal/commit/c775545
    Write-Host 'Patching sqlite3.c for UWP compatibility...'
    $sqlite3cPath = Join-Path $sourceDir 'sqlite3.c'
    $sqlite3c = Get-Content $sqlite3cPath -Raw
    $sqlite3c = $sqlite3c -replace `
        '#if defined\(SQLITE_WIN32_HAS_WIDE\) && defined\(_WIN32\)\s*\r?\n(\s*\{ "GetModuleHandleW")', `
        "#if defined(SQLITE_WIN32_HAS_WIDE) && defined(_WIN32) && (!defined(WINAPI_FAMILY) || (WINAPI_FAMILY != WINAPI_FAMILY_APP))`n`$1"
    Set-Content -Path $sqlite3cPath -Value $sqlite3c -NoNewline
    Write-Host '  Patched GetModuleHandleW guard for UWP'

    # Step 5: Update version in NuGet/package.nuspec
    Write-Host 'Updating NuGet package version...'
    $nuspecContent = Get-Content $nuspecPath -Raw
    $nuspecContent = $nuspecContent -replace '<version>\d+\.\d+\.\d+</version>', "<version>$newVersion</version>"
    Set-Content -Path $nuspecPath -Value $nuspecContent -NoNewline

    # Step 6: Update version in sqlite3rc.h (comma-separated format)
    Write-Host 'Updating sqlite3rc.h resource version...'
    $commaVersion = $newVersion -replace '\.', ','
    $rcContent = Get-Content $rcHeaderPath -Raw
    $rcContent = $rcContent -replace '#define SQLITE_RESOURCE_VERSION \d+,\d+,\d+', "#define SQLITE_RESOURCE_VERSION $commaVersion"
    Set-Content -Path $rcHeaderPath -Value $rcContent -NoNewline

} finally {
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force
        Write-Host 'Cleaned up temp files.'
    }
}


Write-Host "SQLite updated to version $newVersion successfully."

# Step 7: Build all platforms
$slnPath = Join-Path $repoRoot 'SQLite3.Universal.sln'
$platforms = @('ARM', 'ARM64', 'x64', 'x86')

foreach ($platform in $platforms) {
    Write-Host "Building $platform..."
    & msbuild2 $slnPath /p:Configuration=Release /p:Platform=$platform
    if ($LASTEXITCODE -ne 0) {
        throw "Build failed for platform: $platform"
    }
}

Write-Host 'All builds completed successfully.'

# Step 8: Pack NuGet package
$nugetDir = Join-Path $repoRoot 'NuGet'
Write-Host 'Packing NuGet package...'
Push-Location $nugetDir
try {
    & nuget pack
    if ($LASTEXITCODE -ne 0) {
        throw 'NuGet pack failed.'
    }
} finally {
    Pop-Location
}

Write-Host 'NuGet package created successfully.'
