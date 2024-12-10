
Describe 'Module' {
    BeforeEach {
        $DebugPreference = 'Continue'
    }

    It 'Function: Get-PSModuleTest' {
        Get-PSModuleTest -Name 'World' -Verbose | Should -Be 'Hello, World!'
    }
    It 'Function: New-PSModuleTest' {
        New-PSModuleTest -Name 'World' | Should -Be 'Hello, World!'
    }
    It 'Function: Set-PSModuleTest' {
        Set-PSModuleTest -Name 'World' -Verbose | Should -Be 'Hello, World!'
    }
    It 'Function: Test-PSModuleTest' {
        Test-PSModuleTest -Name 'World' | Should -Be 'Hello, World!'
    }
}
