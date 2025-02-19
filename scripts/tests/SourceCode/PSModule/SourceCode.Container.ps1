@{
    Path = Join-Path -Path $PSScriptRoot -ChildPath 'SourceCode.Tests.ps1'
    Data = @{
        Path      = $Path
        TestsPath = $moduleTestsPath
        Debug     = $false
        Verbose   = $false
    }
}
