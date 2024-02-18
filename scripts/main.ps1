$ErrorActionPreference = $env:ErrorAction

Get-ChildItem -Path (Join-Path $env:GITHUB_ACTION_PATH 'scripts' 'helpers') -Filter '*.ps1' -Recurse | ForEach-Object {
    . $_.FullName
}

$env:GITHUB_REPOSITORY_NAME = $env:GITHUB_REPOSITORY -replace '.+/', ''

Write-Output '::group::Initializing...'
Write-Output '-------------------------------------------'
$params = @{
    Name        = $env:GITHUB_REPOSITORY_NAME
    Path        = Join-Path $env:GITHUB_WORKSPACE $env:Path
    Verbose     = $env:Verbose -eq 'true'
    WhatIf      = $env:WhatIf -eq 'true'
    ErrorAction = $ErrorActionPreference
}

if (-not [string]::IsNullOrEmpty($env:CustomTestsPath)) {
    $params['CustomTestsPath'] = Join-Path $env:GITHUB_WORKSPACE $env:CustomTestsPath
}

$params.GetEnumerator() | Sort-Object -Property Name
Write-Output '::endgroup::'

try {
    $failedTests = Test-PSModule @params
} catch {
    Write-Output "::error::$_"
    exit 1
}

if ($ErrorActionPreference -like '*Continue') {
    Write-Output '::warning::Errors were ignored.'
    return
}
