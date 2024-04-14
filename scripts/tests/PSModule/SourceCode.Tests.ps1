[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter', 'Path',
    Justification = 'Path is used to specify the path to the module to test.'
)]
[CmdLetBinding()]
Param(
    [Parameter(Mandatory)]
    [string] $Path
)

BeforeAll {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseDeclaredVarsMoreThanAssignments', '',
        Justification = 'scriptFiles is used in the test.'
    )]
    $scriptFiles = Get-ChildItem -Path $Path -Filter '*.ps1' -Recurse -File
    $functionFiles = Get-ChildItem -Directory -Path $Path |
        Where-Object { $_.Name -in 'public', 'private' } |
        Get-ChildItem -Filter '*.ps1' -File
}

Describe 'PSModule - SourceCode tests' {
    Context 'function/filter' {
        It 'Script filename and function/filter name should match' {
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

        # It 'Script file should only contain one function or filter' {}

        # It 'All script files have tests' {} # Look for the folder name in tests called the same as section/folder name of functions

        It "Should not contain '-Verbose' unless it is disabled using ':`$false' qualifier after it" {
            $issues = @('')
            $scriptFiles | ForEach-Object {
                Select-String -Path $_.FullName -Pattern '\s(-Verbose(?::\$true)?)\b(?!:\$false)' -AllMatches | ForEach-Object {
                    $issues += " - $($_.Path):L$($_.LineNumber)"
                }
            }
            $issues -join [Environment]::NewLine |
                Should -BeNullOrEmpty -Because "the script should not contain '-Verbose' unless it is disabled using ':`$false' qualifier after it."
        }

        It "Should use '`$null = <commands>' instead of '<commands> | Out-Null'" {
            $issues = @('')
            $scriptFiles | ForEach-Object {
                Select-String -Path $_.FullName -Pattern 'Out-Null' -AllMatches | ForEach-Object {
                    $issues += " - $($_.Path):L$($_.LineNumber)"
                }
            }
            $issues -join [Environment]::NewLine |
                Should -BeNullOrEmpty -Because "the script should use '`$null = <commands>' instead of '<commands> | Out-Null'"
        }

        It 'Should not use ternary operations for compatability reasons' {
            $issues = @('')
            $scriptFiles | ForEach-Object {
                Select-String -Path $_.FullName -Pattern '(?<!\|)\s+\?' -AllMatches | ForEach-Object {
                    $issues += " - $($_.Path):L$($_.LineNumber)"
                }
            }
            $issues -join [Environment]::NewLine |
                Should -BeNullOrEmpty -Because 'the script should not use ternary operations for compatability with PS 5.1 and below'
        }
    }

    Context 'Function/filter design' {
        # It 'comment based doc block start is indented with 4 spaces' {}
        # It 'comment based doc is indented with 8 spaces' {}
        # It 'has synopsis for all functions' {}
        # It 'has description for all functions' {}
        # It 'has examples for all functions' {}
        It 'should have [CmdletBinding()] attribute' {
            $issues = @('')
            $functionFiles | ForEach-Object {
                $found = $false
                $filePath = $_.FullName
                $scriptAst = [System.Management.Automation.Language.Parser]::ParseFile($filePath, [ref]$null, [ref]$null)
                $tokens = $scriptAst.FindAll({ $true }, $true)
                foreach ($token in $tokens) {
                    if ($token.TypeName.Name -eq 'CmdletBinding') {
                        $found = $true
                    }
                }
                if (-not $found) {
                    $issues += " - $filePath"
                }
            }
            $issues -join [Environment]::NewLine |
                Should -BeNullOrEmpty -Because 'the script should have [CmdletBinding()] attribute'
        }

        # It 'boolean parameters in CmdletBinding() attribute are written without assignments' {}
        #     I.e. [CmdletBinding(ShouldProcess)] instead of [CmdletBinding(ShouldProcess = $true)]
        # It 'has [OutputType()] attribute' {}
        # It 'has verb 'New','Set','Disable','Enable' etc. and uses "ShoudProcess" in the [CmdletBinding()] attribute' {}
    }

    Context 'Parameter design' {
        # It 'has parameter description for all functions' {}
        # It 'has parameter validation for all functions' {}
        # It 'parameters have [Parameters()] attribute' {}
        # It 'boolean parameters to the [Parameter()] attribute are written without assignments' {}
        #     I.e. [Parameter(Mandatory)] instead of [Parameter(Mandatory = $true)]
        # It 'datatype for parameters are written on the same line as the parameter name' {}
        # It 'datatype for parameters and parameter name are separated by a single space' {}
        # It 'parameters are separated by a blank line' {}
    }

    Context 'Compatability checks' {
        It "Should use '[System.Environment]::ProcessorCount' instead of '$env:NUMBER_OF_PROCESSORS'" {
            $issues = @('')
            $scriptFiles | ForEach-Object {
                Select-String -Path $_.FullName -Pattern '\$env:NUMBER_OF_PROCESSORS' -AllMatches | ForEach-Object {
                    $issues += " - $($_.Path):L$($_.LineNumber)"
                }
            }
            $issues -join [Environment]::NewLine |
                Should -BeNullOrEmpty -Because 'the script should use [System.Environment]::ProcessorCount instead of $env:NUMBER_OF_PROCESSORS'
        }
    }

    Context 'Module manifest' {
        # It 'Module Manifest exists (maifest.psd1 or modulename.psd1)' {}
        # It 'Module Manifest is valid' {}
    }
}
