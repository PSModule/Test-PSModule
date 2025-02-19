@{
    Configuration = @{
        Run          = @{
            Path      = $Path
            Container = $containers
            PassThru  = $true
        }
        TestResult   = @{
            Enabled = $true
        }
        CodeCoverage = @{
            Enabled               = $true
            OutputFormat          = 'JaCoCo'
            OutputEncoding        = 'UTF8'
            CoveragePercentTarget = 75
        }
        Output       = @{
            Verbosity = 'Detailed'
        }
    }
}
