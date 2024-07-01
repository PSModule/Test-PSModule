[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter', '',
    Justification = 'Parameters are used in the test.'
)]
[CmdLetBinding()]
Param(
    [Parameter(Mandatory)]
    [string] $Path,

    [Parameter(Mandatory)]
    [string] $TestsPath
)

BeforeAll {
    $scriptFiles = Get-ChildItem -Path $Path -Include *.psm1, *.ps1 -Recurse -File
    $functionFiles = Get-ChildItem -Directory -Path $Path |
        Where-Object { $_.Name -in 'public', 'private' } |
        Get-ChildItem -Filter '*.ps1' -File

    $publicFunctionFiles = Get-ChildItem -Directory -Path (Join-Path -Path $Path -ChildPath 'public') -File -Filter '*.ps1'

    Write-Verbose "Found $($scriptFiles.Count) script files in $Path"
    Write-Verbose "Found $($functionFiles.Count) function files in $Path"
    Write-Verbose "Found $($publicFunctionFiles.Count) public function files in $Path"
}

Describe 'PSModule - SourceCode tests' {
    Context 'function/filter' {
        It 'Should contain one function or filter' {
            $issues = @('')
            $functionFiles | ForEach-Object {
                $filePath = $_.FullName
                $relativePath = $filePath.Replace($Path, '').Trim('\').Trim('/')
                $Ast = [System.Management.Automation.Language.Parser]::ParseFile($filePath, [ref]$null, [ref]$null)
                $tokens = $Ast.FindAll( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] } , $true )
                if ($tokens.count -ne 1) {
                    $issues += " - $relativePath - $($tokens.Name)"
                }
            }
            $issues -join [Environment]::NewLine |
                Should -BeNullOrEmpty -Because 'the script should contain one function or filter'
        }

        It 'Should have matching filename and function/filter name' {
            $issues = @('')
            $functionFiles | ForEach-Object {
                $filePath = $_.FullName
                $fileName = $_.BaseName
                $relativePath = $filePath.Replace($Path, '').Trim('\').Trim('/')
                $Ast = [System.Management.Automation.Language.Parser]::ParseFile($filePath, [ref]$null, [ref]$null)
                $tokens = $Ast.FindAll( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] } , $true )
                if ($tokens.Name -ne $fileName) {
                    $issues += " - $relativePath - $($tokens.Name)"
                }
            }
            $issues -join [Environment]::NewLine |
                Should -BeNullOrEmpty -Because 'the script files should be called the same as the function they contain'
        }

        It 'All public functions/filters have tests' {
            $issues = @('')

            $testFiles = Get-ChildItem -Path $TestsPath -Recurse -File -Filter '*.ps1'
            $functionsInTestFiles = $testFiles | ForEach-Object {
                $ast = [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$null)
                $ast.FindAll(
                    {
                        param($node)
                        $node -is [System.Management.Automation.Language.CommandAst] -and
                        $node.GetCommandName() -ne $null
                    },
                    $true
                ) | ForEach-Object {
                    $_.GetCommandName()
                } | Sort-Object -Unique
            }

            $publicFunctionFiles | ForEach-Object {
                $filePath = $_.FullName
                $relativePath = $filePath.Replace($Path, '').Trim('\').Trim('/')
                $Ast = [System.Management.Automation.Language.Parser]::ParseFile($filePath, [ref]$null, [ref]$null)
                $tokens = $Ast.FindAll( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] } , $true )
                $functionName = $tokens.Name
                if ($functionsInTestFiles -notcontains $functionName) {
                    $issues += " - $relativePath - $functionName"
                }
            }
            $issues -join [Environment]::NewLine |
                Should -BeNullOrEmpty -Because 'a test should exist for each of the functions in the module'
        }

        It "Should not contain '-Verbose' unless it is disabled using ':`$false' qualifier after it" {
            $issues = @('')
            $scriptFiles | ForEach-Object {
                $filePath = $_.FullName
                $relativePath = $filePath.Replace($Path, '').Trim('\').Trim('/')
                Select-String -Path $filePath -Pattern '\s(-Verbose(?::\$true)?)\b(?!:\$false)' -AllMatches | ForEach-Object {
                    $issues += " - $relativePath`:L$($_.LineNumber) - $($_.Line)"
                }
            }
            $issues -join [Environment]::NewLine |
                Should -BeNullOrEmpty -Because "the script should not contain '-Verbose' unless it is disabled using ':`$false' qualifier after it."
        }

        It "Should use '`$null = ...' instead of '... | Out-Null'" {
            $issues = @('')
            $scriptFiles | ForEach-Object {
                $filePath = $_.FullName
                $relativePath = $filePath.Replace($Path, '').Trim('\').Trim('/')
                Select-String -Path $filePath -Pattern 'Out-Null' -AllMatches | ForEach-Object {
                    $issues += " - $relativePath`:L$($_.LineNumber) - $($_.Line)"
                }
            }
            $issues -join [Environment]::NewLine |
                Should -BeNullOrEmpty -Because "the script should use '`$null = ...' instead of '... | Out-Null'"
        }

        It 'Should not use ternary operations for compatability reasons' {
            $issues = @('')
            $scriptFiles | ForEach-Object {
                $filePath = $_.FullName
                $relativePath = $filePath.Replace($Path, '').Trim('\').Trim('/')
                Select-String -Path $filePath -Pattern '(?<!\|)\s+\?' -AllMatches | ForEach-Object {
                    $issues += " - $relativePath`:L$($_.LineNumber) - $($_.Line)"
                }
            }
            $issues -join [Environment]::NewLine |
                Should -BeNullOrEmpty -Because 'the script should not use ternary operations for compatability with PS 5.1 and below'
        }

        It 'all powershell keywords are lowercase' {
            $issues = @('')
            $scriptFiles | ForEach-Object {
                $filePath = $_.FullName
                $relativePath = $filePath.Replace($Path, '').Trim('\').Trim('/')

                $errors = $null
                $tokens = $null
                [System.Management.Automation.Language.Parser]::ParseFile($FilePath, [ref]$tokens, [ref]$errors)

                foreach ($token in $tokens) {
                    $keyword = $token.Text
                    $lineNumber = $token.Extent.StartLineNumber
                    $columnNumber = $token.Extent.StartColumnNumber
                    if (($token.TokenFlags -match 'Keyword') -and ($keyword -cne $keyword.ToLower())) {
                        $issues += " - $relativePath`:L$lineNumber`:C$columnNumber - $keyword"
                    }
                }
            }
            $issues -join [Environment]::NewLine | Should -BeNullOrEmpty -Because 'all powershell keywords should be lowercase'
        }

        # It 'comment based doc block start is indented with 4 spaces' {}
        # It 'comment based doc is indented with 8 spaces' {}
        # It 'has synopsis for all functions' {}
        # It 'has description for all functions' {}
        # It 'has examples for all functions' {}

        It 'Should have [CmdletBinding()] attribute' {
            $issues = @('')
            $functionFiles | ForEach-Object {
                $found = $false
                $filePath = $_.FullName
                $relativePath = $filePath.Replace($Path, '').Trim('\').Trim('/')
                $scriptAst = [System.Management.Automation.Language.Parser]::ParseFile($filePath, [ref]$null, [ref]$null)
                $tokens = $scriptAst.FindAll({ $true }, $true)
                foreach ($token in $tokens) {
                    if ($token.TypeName.Name -eq 'CmdletBinding') {
                        $found = $true
                    }
                }
                if (-not $found) {
                    $issues += " - $relativePath"
                }
            }
            $issues -join [Environment]::NewLine |
                Should -BeNullOrEmpty -Because 'the script should have [CmdletBinding()] attribute'
        }

        It 'Should have a param() block' {
            $issues = @('')
            $functionFiles | ForEach-Object {
                $found = $false
                $filePath = $_.FullName
                $relativePath = $filePath.Replace($Path, '').Trim('\').Trim('/')
                $scriptAst = [System.Management.Automation.Language.Parser]::ParseFile($filePath, [ref]$null, [ref]$null)
                $tokens = $scriptAst.FindAll({ $args[0] -is [System.Management.Automation.Language.ParamBlockAst] }, $true)
                foreach ($token in $tokens) {
                    if ($token.count -eq 1) {
                        $found = $true
                    }
                }
                if (-not $found) {
                    $issues += " - $relativePath"
                }
            }
            $issues -join [Environment]::NewLine |
                Should -BeNullOrEmpty -Because 'the script should have a param() block'
        }

        # It 'boolean parameters in CmdletBinding() attribute are written without assignments' {}
        #     I.e. [CmdletBinding(ShouldProcess)] instead of [CmdletBinding(ShouldProcess = $true)]
        # It 'has [OutputType()] attribute' {}
    }

    Context 'Parameter design' {
        # It 'has parameter description for all functions' {}
        # It 'parameters have [Parameter()] attribute' {}
        # It 'boolean parameters to the [Parameter()] attribute are written without assignments' {}
        #     I.e. [Parameter(Mandatory)] instead of [Parameter(Mandatory = $true)]
        # It 'datatype for parameters are written on the same line as the parameter name' {}
        # It 'datatype for parameters and parameter name are separated by a single space' {}
        # It 'parameters are separated by a blank line' {}
    }

    Context 'Compatability checks' {
        It "Should use '[System.Environment]::ProcessorCount' instead of '`$env:NUMBER_OF_PROCESSORS'" {
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
