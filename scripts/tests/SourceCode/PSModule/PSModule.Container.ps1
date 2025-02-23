@{
    Path = Get-ChildItem -Path $PSScriptRoot -Filter *.Tests.ps1 | Select-Object -ExpandProperty FullName
    Data = @{
        Path      = Resolve-Path "$env:GITHUB_ACTION_INPUT_Run_Path/src" | Select-Object -ExpandProperty Path
        TestsPath = Resolve-Path $env:GITHUB_ACTION_INPUT_Run_Path/../tests | Select-Object -ExpandProperty Path
        Debug     = $false
        Verbose   = $false
    }
}
