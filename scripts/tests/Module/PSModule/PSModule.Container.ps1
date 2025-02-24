@{
    Path = Get-ChildItem -Path $PSScriptRoot -Filter *.Tests.ps1 | Select-Object -ExpandProperty FullName
    Data = @{
        Path    = Resolve-Path -Path "$env:GITHUB_ACTION_INPUT_Run_Path/outputs/modules/$env:ModuleName" | Select-Object -ExpandProperty Path
        Debug   = $false
        Verbose = $false
    }
}
