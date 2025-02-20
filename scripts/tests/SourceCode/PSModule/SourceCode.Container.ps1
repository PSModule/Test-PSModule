@{
    Path = Get-ChildItem -Path $PSScriptRoot -Filter *.Tests.ps1 | Select-Object -ExpandProperty FullName
    Data = @{
        Path      = Resolve-Path -Path "$env:GITHUB_ACTION_INPUT_TEST_PSMODULE_Path" | Select-Object -ExpandProperty Path
        TestsPath = Resolve-Path -Path "$env:GITHUB_ACTION_INPUT_TEST_PSMODULE_Path/tests" | Select-Object -ExpandProperty Path
        Debug     = $false
        Verbose   = $false
    }
}
