$ErrorActionPreference = $env:ErrorAction

Write-Output '::group::Initializing...'
Write-Output '-------------------------------------------'
Write-Output 'Action inputs:'
$params = @{
    Name        = $env:Name
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
