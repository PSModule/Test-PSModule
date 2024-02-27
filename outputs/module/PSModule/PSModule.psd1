@{
    RootModule            = 'PSModule.psm1'
    ModuleVersion         = '0.0.1'
    CompatiblePSEditions  = 'Core', 'Desktop'
    GUID                  = '567bd93a-a0d5-4715-8cdf-6b5089d73065'
    Author                = 'PSModule'
    CompanyName           = 'PSModule'
    Copyright             = '(c) 2024 PSModule. All rights reserved.'
    Description           = 'PSModule Framework Test Module'
    PowerShellVersion     = '7.0'
    ProcessorArchitecture = 'None'
    RequiredAssemblies    = @()
    ScriptsToProcess      = @()
    TypesToProcess        = @()
    FormatsToProcess      = @()
    NestedModules         = @()
    FunctionsToExport     = 'Test-PSModule'
    CmdletsToExport       = @()
    AliasesToExport       = '*'
    ModuleList            = @()
    FileList              = 'PSModule.psd1', 'PSModule.psm1'
    PrivateData           = @{
        PSData = @{
            Tags = 'PSEdition_Desktop', 'PSEdition_Core'
        }
    }
}
