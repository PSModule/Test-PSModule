@{
    TestResult   = @{
        Enabled = $true
    }
    CodeCoverage = @{
        Enabled               = $true
        OutputFormat          = 'JaCoCo'
        OutputEncoding        = 'UTF8'
        CoveragePercentTarget = 80
    }
    Output       = @{
        Verbosity = 'Detailed'
    }
}
