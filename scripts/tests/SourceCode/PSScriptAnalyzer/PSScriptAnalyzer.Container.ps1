@{
    Path = Get-ChildItem -Path $PSScriptRoot -Filter *.Tests.ps1 | Select-Object -ExpandProperty FullName
    Data = @{
        Path             = Resolve-Path -Path "$env:GITHUB_ACTION_INPUT_TEST_PSMODULE_Path" | Select-Object -ExpandProperty Path
        SettingsFilePath = Resolve-Path -Path "$PSScriptRoot/PSScriptAnalyzer.Settings.psd1"
        Debug            = $false
        Verbose          = $false
    }
}
