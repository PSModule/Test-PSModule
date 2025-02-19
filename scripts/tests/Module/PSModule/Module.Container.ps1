@{
    Path = Join-Path -Path $PSScriptRoot -ChildPath 'Module.Tests.ps1'
    Data = @{
        Path    = $Path
        Debug   = $false
        Verbose = $false
    }
}
