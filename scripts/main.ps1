$ErrorActionPreference = $env:ErrorAction

Get-ChildItem -Path (Join-Path $env:GITHUB_ACTION_PATH 'scripts' 'helpers') -Filter '*.ps1' -Recurse | ForEach-Object {
    Write-Verbose "[$($_.FullName)]" -Verbose
    . $_.FullName
}

$moduleName = [string]::IsNullOrEmpty($env:Name) ? $env:GITHUB_REPOSITORY -replace '.+/', '' : $env:Name

$params = @{
    Verbose     = $env:Verbose -eq 'true'
    WhatIf      = $env:WhatIf -eq 'true'
    ErrorAction = $ErrorActionPreference
}

$codeToTest = Join-Path $env:GITHUB_WORKSPACE $env:Path $moduleName

try {
    $params = @{
        Path      = $codeToTest
        TestsPath = (Test-Path -Path $ModuleTestsPath) ? $ModuleTestsPath : $null
    }
    $failedTests = Invoke-PSModuleTest @params
} catch {
    if ($ErrorActionPreference -like '*Continue') {
        Write-Output '::warning::Errors were ignored.'
        return
    } else {
        throw "$($_.Exception.Message)"
    }
}
