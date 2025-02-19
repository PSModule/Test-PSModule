@{
    Configuration = @{
        CodeCoverage = @{
            Enabled        = $true
            OutputFormat   = 'JaCoCo'
            OutputEncoding = 'UTF8'
        }
        Output       = @{
            Verbosity = 'Detailed'
        }
    }
}
