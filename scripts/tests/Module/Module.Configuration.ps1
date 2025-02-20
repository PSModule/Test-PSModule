@{
    TestResult   = @{
        Enabled       = $true
        TestSuiteName = 'Module'
    }
    CodeCoverage = @{
        Enabled        = $true
        OutputFormat   = 'JaCoCo'
        OutputEncoding = 'UTF8'
    }
    Output       = @{
        Verbosity = 'Detailed'
    }
}
