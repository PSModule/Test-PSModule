@{
    Path = Get-ChildItem -Path $PSScriptRoot -Filter *.Tests.ps1 | Select-Object -ExpandProperty FullName
    Data = @{
        Path      = $env:GITHUB_ACTION_INPUT_Run_Path
        TestsPath = $env:LocalTestPath
        Debug     = $false
        Verbose   = $false
    }
}
