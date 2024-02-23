$VerbosePreference = 'Continue'
Install-PSResource -Name 'Utilities', 'powershell-yaml' -TrustRepository

Start-LogGroup 'Loading helper scripts'
Get-ChildItem -Path (Join-Path -Path $env:GITHUB_ACTION_PATH -ChildPath 'scripts' 'helpers') -Filter '*.ps1' -Recurse |
    ForEach-Object { Write-Verbose "[$($_.FullName)]"; . $_.FullName }
Stop-LogGroup

$moduleName = ($env:Name | IsNullOrEmpty) ? $env:GITHUB_REPOSITORY -replace '.+/' : $env:Name
$codeToTest = Join-Path -Path $env:GITHUB_WORKSPACE -ChildPath $env:Path $moduleName
if (-not (Test-Path -Path $codeToTest)) {
    throw "Module path [$codeToTest] does not exist."
}

$params = @{
    Name = $moduleName
    Path = $codeToTest
}
Test-PSModule @params
