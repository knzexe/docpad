[CmdletBinding()]
param(
  [string]$ReleaseVersion
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-CheckedCommand {
  param(
    [Parameter(Mandatory = $true)]
    [string]$FilePath,
    [Parameter(Mandatory = $true)]
    [string[]]$Arguments
  )

  & $FilePath @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "$FilePath failed with exit code $LASTEXITCODE."
  }
}

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$pubspecPath = Join-Path $repositoryRoot 'pubspec.yaml'
$pubspec = Get-Content -LiteralPath $pubspecPath -Raw
$versionMatch = [regex]::Match($pubspec, '(?m)^version:\s*(\d+\.\d+\.\d+)')
if (-not $versionMatch.Success) {
  throw 'Could not read the app version from pubspec.yaml.'
}

$packageVersion = $versionMatch.Groups[1].Value
if ([string]::IsNullOrWhiteSpace($ReleaseVersion)) {
  $ReleaseVersion = $packageVersion
}
if ($ReleaseVersion -notmatch '^\d+\.\d+\.\d+$' -or
    $ReleaseVersion -ne $packageVersion) {
  throw "Release version $ReleaseVersion must match pubspec.yaml version $packageVersion."
}

$certificateBase64 = $env:WINDOWS_SIGNING_CERTIFICATE_BASE64
$certificatePassword = $env:WINDOWS_SIGNING_CERTIFICATE_PASSWORD
if ([string]::IsNullOrWhiteSpace($certificateBase64) -or
    [string]::IsNullOrWhiteSpace($certificatePassword)) {
  throw 'Set WINDOWS_SIGNING_CERTIFICATE_BASE64 and WINDOWS_SIGNING_CERTIFICATE_PASSWORD.'
}

$hasSupabaseUrl = -not [string]::IsNullOrWhiteSpace($env:SUPABASE_URL)
$hasSupabaseKey = -not [string]::IsNullOrWhiteSpace($env:SUPABASE_PUBLISHABLE_KEY)
if ($hasSupabaseUrl -xor $hasSupabaseKey) {
  throw 'Set both SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY, or neither.'
}

$signToolCommand = Get-Command 'signtool.exe' -ErrorAction SilentlyContinue
$signTool = if ($null -ne $signToolCommand) {
  $signToolCommand.Source
} else {
  $null
}
if ([string]::IsNullOrWhiteSpace($signTool)) {
  $windowsKitsPath = Join-Path ${env:ProgramFiles(x86)} 'Windows Kits\10\bin'
  if (Test-Path -LiteralPath $windowsKitsPath -PathType Container) {
    $signTool = Get-ChildItem -LiteralPath $windowsKitsPath -Directory |
      Sort-Object Name -Descending |
      ForEach-Object { Join-Path $_.FullName 'x64\signtool.exe' } |
      Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } |
      Select-Object -First 1
  }
}
if ([string]::IsNullOrWhiteSpace($signTool)) {
  throw 'Windows SDK signtool.exe was not found.'
}

$isccCommand = Get-Command 'ISCC.exe' -ErrorAction SilentlyContinue
$iscc = if ($null -ne $isccCommand) {
  $isccCommand.Source
} else {
  $null
}
if ([string]::IsNullOrWhiteSpace($iscc)) {
  $defaultIscc = Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe'
  if (Test-Path -LiteralPath $defaultIscc -PathType Leaf) {
    $iscc = $defaultIscc
  }
}
if ([string]::IsNullOrWhiteSpace($iscc)) {
  throw 'Inno Setup 6 ISCC.exe was not found. Install Inno Setup 6 first.'
}

$certificatePath = Join-Path $env:TEMP ("docpad-signing-{0}.pfx" -f [guid]::NewGuid())
try {
  $certificateBytes = [Convert]::FromBase64String($certificateBase64)
  [System.IO.File]::WriteAllBytes($certificatePath, $certificateBytes)
  $certificateBytes = $null
  $certificateBase64 = $null
  $env:WINDOWS_SIGNING_CERTIFICATE_BASE64 = $null

  $env:DOC_PAD_SIGNING_CERTIFICATE_PATH = $certificatePath
  $env:DOC_PAD_SIGNTOOL_PATH = $signTool

  Invoke-CheckedCommand -FilePath 'flutter' -Arguments @('pub', 'get')

  $flutterArguments = @('build', 'windows', '--release')
  if ($hasSupabaseUrl) {
    $flutterArguments += "--dart-define=SUPABASE_URL=$env:SUPABASE_URL"
    $flutterArguments += "--dart-define=SUPABASE_PUBLISHABLE_KEY=$env:SUPABASE_PUBLISHABLE_KEY"
  }
  Invoke-CheckedCommand -FilePath 'flutter' -Arguments $flutterArguments

  $appExecutable = Join-Path $repositoryRoot 'build\windows\x64\runner\Release\docpad.exe'
  if (-not (Test-Path -LiteralPath $appExecutable -PathType Leaf)) {
    throw "Flutter did not produce the expected app executable: $appExecutable"
  }

  $signArguments = @(
    'sign',
    '/f', $certificatePath,
    '/p', $certificatePassword,
    '/fd', 'SHA256',
    '/tr', 'http://timestamp.digicert.com',
    '/td', 'SHA256',
    $appExecutable
  )
  Invoke-CheckedCommand -FilePath $signTool -Arguments $signArguments
  Invoke-CheckedCommand -FilePath $signTool -Arguments @('verify', '/pa', '/v', $appExecutable)

  $installerScript = Join-Path $PSScriptRoot 'docpad.iss'
  $powerShellExe = (Get-Process -Id $PID).Path
  if ([string]::IsNullOrWhiteSpace($powerShellExe)) {
    throw 'Could not locate the current PowerShell executable.'
  }
  $signingScript = Join-Path $PSScriptRoot 'sign_file.ps1'
  $innoSignToolCommand = '$q{0}$q -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $q{1}$q $f' -f $powerShellExe, $signingScript
  Invoke-CheckedCommand -FilePath $iscc -Arguments @(
    "-dAppVersion=$ReleaseVersion",
    "-sDocPadSignTool=$innoSignToolCommand",
    $installerScript
  )

  $installerPath = Join-Path $repositoryRoot "build\windows\installer\RaifaMedicineSetup-$ReleaseVersion-x64.exe"
  if (-not (Test-Path -LiteralPath $installerPath -PathType Leaf)) {
    throw "Inno Setup did not produce the expected installer: $installerPath"
  }

  Invoke-CheckedCommand -FilePath $signTool -Arguments @('verify', '/pa', '/v', $installerPath)

  Write-Output "Signed installer created: $installerPath"
}
finally {
  if (Test-Path -LiteralPath $certificatePath -PathType Leaf) {
    Remove-Item -LiteralPath $certificatePath -Force
  }
  $certificatePassword = $null
  $env:WINDOWS_SIGNING_CERTIFICATE_BASE64 = $null
  $env:WINDOWS_SIGNING_CERTIFICATE_PASSWORD = $null
  $env:DOC_PAD_SIGNING_CERTIFICATE_PATH = $null
  $env:DOC_PAD_SIGNTOOL_PATH = $null
}
