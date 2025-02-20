@{
    Path = Get-ChildItem -Path $PSScriptRoot -Filter *.Tests.ps1 | Select-Object -ExpandProperty FullName
    Data = @{
        Path             = "$env:GITHUB_ACTION_INPUT_Run_Path/output/modules/$env:ModuleName"
        SettingsFilePath = "$PSScriptRoot/PSScriptAnalyzer.Settings.psd1"
        Debug            = $false
        Verbose          = $false
    }
}
