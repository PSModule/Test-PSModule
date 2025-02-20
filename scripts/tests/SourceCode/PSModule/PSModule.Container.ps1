@{
    Path = Get-ChildItem -Path $PSScriptRoot -Filter *.Tests.ps1 | Select-Object -ExpandProperty FullName
    Data = @{
        Path      = "$env:GITHUB_ACTION_INPUT_Run_Path/src"
        TestsPath = "$env:GITHUB_ACTION_INPUT_Run_Path/tests"
        Debug     = $false
        Verbose   = $false
    }
}
