[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter', 'Path',
    Justification = 'Path is used to specify the path to the module to test.'
)]
[CmdLetBinding()]
Param(
    [Parameter(Mandatory)]
    [string] $Path
)

# These tests are for the whole module and its parts. The scope of these tests are on the src folder and the specific module folder within it.
Context 'Module design tests' {
    Describe 'Script files' {
        It 'Script file name and function/filter name should match' {

            $scriptFiles = @()

            Get-ChildItem -Path $Path -Filter '*.ps1' -Recurse -File | ForEach-Object {
                $fileContent = Get-Content -Path $_.FullName -Raw
                if ($fileContent -match '^(?:function|filter)\s+([a-zA-Z][a-zA-Z0-9-]*)') {
                    $functionName = $matches[1]
                    $fileName = $_.BaseName
                    $relativePath = $_.FullName.Replace($Path, '').Trim('\').Trim('/')
                    $scriptFiles += @{
                        fileName     = $fileName
                        filePath     = $relativePath
                        functionName = $functionName
                    }
                }
            }

            $issues = @('')
            $issues += $scriptFiles | Where-Object { $_.filename -ne $_.functionName } | ForEach-Object {
                " - $($_.filePath): Function/filter name [$($_.functionName)]. Change file name or function/filter name so they match."
            }
            $issues -join [Environment]::NewLine |
                Should -BeNullOrEmpty -Because 'the script files should be called the same as the function they contain'
        }

        # It 'Script file should only contain max one function or filter' {}

        # It 'has tests for the section of functions' {} # Look for the folder name in tests called the same as section/folder name of functions

    }

    Describe 'Function/filter design' {
        # It 'comment based doc block start is indented with 4 spaces' {}
        # It 'comment based doc is indented with 8 spaces' {}
        # It 'has synopsis for all functions' {}
        # It 'has description for all functions' {}
        # It 'has examples for all functions' {}
        # It 'has output documentation for all functions' {}
        # It 'has [CmdletBinding()] attribute' {}
        # It 'boolean parameters in CmdletBinding() attribute are written without assignments' {}
        #     I.e. [CmdletBinding(ShouldProcess)] instead of [CmdletBinding(ShouldProcess = $true)]
        # It 'has [OutputType()] attribute' {}
        # It 'has verb 'New','Set','Disable','Enable' etc. and uses "ShoudProcess" in the [CmdletBinding()] attribute' {}
    }

    Describe 'Parameter design' {
        # It 'has parameter description for all functions' {}
        # It 'has parameter validation for all functions' {}
        # It 'parameters have [Parameters()] attribute' {}
        # It 'boolean parameters to the [Parameter()] attribute are written without assignments' {}
        #     I.e. [Parameter(Mandatory)] instead of [Parameter(Mandatory = $true)]
        # It 'datatype for parameters are written on the same line as the parameter name' {}
        # It 'datatype for parameters and parameter name are separated by a single space' {}
        # It 'parameters are separated by a blank line' {}
    }
}

Context 'Manifest file' {
    It 'has a manifest file' {}
    It 'has a valid license URL' {}
    It 'has a valid project URL' {}
    It 'has a valid icon URL' {}
    It 'has a valid help URL' {}
}
