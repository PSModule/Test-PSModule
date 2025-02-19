@{
    Path = Join-Path $PSSATestsPath 'PSScriptAnalyzer.Tests.ps1'
    Data = @{
        Path             = $Path
        SettingsFilePath = Join-Path -Path $PSScriptRoot -ChildPath 'PSScriptAnalyzer.Settings.psd1'
        Debug            = $false
        Verbose          = $false
    }
}
