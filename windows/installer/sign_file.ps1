[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string]$FilePath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$signTool = $env:DOC_PAD_SIGNTOOL_PATH
$certificatePath = $env:DOC_PAD_SIGNING_CERTIFICATE_PATH
$certificatePassword = $env:WINDOWS_SIGNING_CERTIFICATE_PASSWORD
if ([string]::IsNullOrWhiteSpace($signTool) -or
    [string]::IsNullOrWhiteSpace($certificatePath) -or
    [string]::IsNullOrWhiteSpace($certificatePassword)) {
  throw 'Signing environment is incomplete.'
}
if (-not (Test-Path -LiteralPath $FilePath -PathType Leaf)) {
  throw "The file to sign was not found: $FilePath"
}

& $signTool sign `
  /f $certificatePath `
  /p $certificatePassword `
  /fd SHA256 `
  /tr 'http://timestamp.digicert.com' `
  /td SHA256 `
  $FilePath
if ($LASTEXITCODE -ne 0) {
  throw "SignTool failed to sign $FilePath with exit code $LASTEXITCODE."
}
