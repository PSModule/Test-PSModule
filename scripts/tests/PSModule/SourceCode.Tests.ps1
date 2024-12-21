[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter', '',
    Justification = 'Parameters are used in the test.'
)]
[CmdLetBinding()]
Param(
    # The path to the 'src' folder of the repo.
    [Parameter(Mandatory)]
    [string] $Path,

    # The path to the 'tests' folder of the repo.
    [Parameter(Mandatory)]
    [string] $TestsPath
)

BeforeAll {
    $scriptFiles = Get-ChildItem -Path $Path -Include *.psm1, *.ps1 -Recurse -File
    LogGroup "Found $($scriptFiles.Count) script files in [$Path]" {
        $scriptFiles | ForEach-Object {
            Write-Verbose " - $($_.FullName)" -Verbose
        }
    }
    $functionsPath = Join-Path -Path $Path -ChildPath 'functions'
    $functionFiles = (Test-Path -Path $functionsPath) ? (Get-ChildItem -Path $functionsPath -File -Filter '*.ps1' -Recurse) : $null
    LogGroup "Found $($functionFiles.Count) function files in [$functionsPath]" {
        $functionFiles | ForEach-Object {
            Write-Verbose " - $($_.FullName)" -Verbose
        }
    }
    $privateFunctionsPath = Join-Path -Path $functionsPath -ChildPath 'private'
    $privateFunctionFiles = (Test-Path -Path $privateFunctionsPath) ?
        (Get-ChildItem -Path $privateFunctionsPath -File -Filter '*.ps1' -Recurse) : $null
    LogGroup "Found $($privateFunctionFiles.Count) private function files in [$privateFunctionsPath]" {
        $privateFunctionFiles | ForEach-Object {
            Write-Verbose " - $($_.FullName)" -Verbose
        }
    }
    $publicFunctionsPath = Join-Path -Path $functionsPath -ChildPath 'public'
    $publicFunctionFiles = (Test-Path -Path $publicFunctionsPath) ? (Get-ChildItem -Path $publicFunctionsPath -File -Filter '*.ps1' -Recurse) : $null
    LogGroup "Found $($publicFunctionFiles.Count) public function files in [$publicFunctionsPath]" {
        $publicFunctionFiles | ForEach-Object {
            Write-Verbose " - $($_.FullName)" -Verbose
        }
    }
    $variablesPath = Join-Path -Path $Path -ChildPath 'variables'
    $variableFiles = (Test-Path -Path $variablesPath) ? (Get-ChildItem -Path $variablesPath -File -Filter '*.ps1' -Recurse) : $null
    LogGroup "Found $($variableFiles.Count) variable files in [$variablesPath]" {
        $variableFiles | ForEach-Object {
            Write-Verbose " - $($_.FullName)" -Verbose
        }
    }
    $privateVariablesPath = Join-Path -Path $variablesPath -ChildPath 'private'
    $privateVariableFiles = (Test-Path -Path $privateVariablesPath) ?
        (Get-ChildItem -Path $privateVariablesPath -File -Filter '*.ps1' -Recurse) : $null
    LogGroup "Found $($privateVariableFiles.Count) private variable files in [$privateVariablesPath]" {
        $privateVariableFiles | ForEach-Object {
            Write-Verbose " - $($_.FullName)" -Verbose
        }
    }
    $publicVariablesPath = Join-Path -Path $variablesPath -ChildPath 'public'
    $publicVariableFiles = (Test-Path -Path $publicVariablesPath) ?
        (Get-ChildItem -Path $publicVariablesPath -File -Filter '*.ps1' -Recurse) : $null
    LogGroup "Found $($publicVariableFiles.Count) public variable files in [$publicVariablesPath]" {
        $publicVariableFiles | ForEach-Object {
            Write-Verbose " - $($_.FullName)" -Verbose
        }
    }
    $classPath = Join-Path -Path $Path -ChildPath 'classes'
    $classFiles = (Test-Path -Path $classPath) ? (Get-ChildItem -Path $classPath -File -Filter '*.ps1' -Recurse) : $null
    LogGroup "Found $($classFiles.Count) class files in [$classPath]" {
        $classFiles | ForEach-Object {
            Write-Verbose " - $($_.FullName)" -Verbose
        }
    }
    $privateClassPath = Join-Path -Path $classPath -ChildPath 'private'
    $privateClassFiles = (Test-Path -Path $privateClassPath) ?
        (Get-ChildItem -Path $privateClassPath -File -Filter '*.ps1' -Recurse) : $null
    LogGroup "Found $($privateClassFiles.Count) private class files in [$privateClassPath]" {
        $privateClassFiles | ForEach-Object {
            Write-Verbose " - $($_.FullName)" -Verbose
        }
    }
    $publicClassPath = Join-Path -Path $classPath -ChildPath 'public'
    $publicClassFiles = (Test-Path -Path $publicClassPath) ?
        (Get-ChildItem -Path $publicClassPath -File -Filter '*.ps1' -Recurse) : $null
    LogGroup "Found $($publicClassFiles.Count) public class files in [$publicClassPath]" {
        $publicClassFiles | ForEach-Object {
            Write-Verbose " - $($_.FullName)" -Verbose
        }
    }
}

Describe 'PSModule - SourceCode tests' {
    Context 'function/filter' {
        It 'Should contain one function or filter (ID: FunctionCount)' {
            $issues = @('')
            $functionFiles | ForEach-Object {
                $filePath = $_.FullName
                $relativePath = $filePath.Replace($Path, '').Trim('\').Trim('/')
                $skipTest = Select-String -Path $filePath -Pattern '#SkipTest:(?<Type>.+):(?<Reason>.+)' -AllMatches
                if ($skipTest.Matches.Count -gt 0 -and $skipTest.Matches.Groups['Type'].Value -eq 'FunctionCount') {
                    Write-Verbose " - $relativePath - $($skipTest.Matches.Groups['Reason'].Value)" -Verbose
                    continue
                }
                $Ast = [System.Management.Automation.Language.Parser]::ParseFile($filePath, [ref]$null, [ref]$null)
                $tokens = $Ast.FindAll( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] } , $true )
                if ($tokens.count -ne 1) {
                    $issues += " - $relativePath - $($tokens.Name)"
                }
            }
            $issues -join [Environment]::NewLine |
                Should -BeNullOrEmpty -Because 'the script should contain one function or filter'
        }

        It 'Should have matching filename and function/filter name (ID: FunctionName)' {
            $issues = @('')
            $functionFiles | ForEach-Object {
                $filePath = $_.FullName
                $fileName = $_.BaseName
                $relativePath = $filePath.Replace($Path, '').Trim('\').Trim('/')
                $skipTest = Select-String -Path $filePath -Pattern '#SkipTest:(?<Type>.+):(?<Reason>.+)' -AllMatches
                if ($skipTest.Matches.Count -gt 0 -and $skipTest.Matches.Groups['Type'].Value -eq 'FunctionName') {
                    Write-Verbose " - $relativePath - $($skipTest.Matches.Groups['Reason'].Value)" -Verbose
                    continue
                }
                $Ast = [System.Management.Automation.Language.Parser]::ParseFile($filePath, [ref]$null, [ref]$null)
                $tokens = $Ast.FindAll( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] } , $true )
                if ($tokens.Name -ne $fileName) {
                    $issues += " - $relativePath - $($tokens.Name)"
                }
            }
            $issues -join [Environment]::NewLine |
                Should -BeNullOrEmpty -Because 'the script files should be called the same as the function they contain'
        }

        It 'All public functions/filters have tests (ID: FunctionTest)' {
            $issues = @('')

            # Get commands used in tests from the files in 'tests' folder.
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

            # Get all the functions in the public function files and check if they have a test.
            $publicFunctionFiles | ForEach-Object {
                $filePath = $_.FullName
                $relativePath = $filePath.Replace($Path, '').Trim('\').Trim('/')
                $skipTest = Select-String -Path $filePath -Pattern '#SkipTest:(?<Type>.+):(?<Reason>.+)' -AllMatches
                if ($skipTest.Matches.Count -gt 0 -and $skipTest.Matches.Groups['Type'].Value -eq 'FunctionTest') {
                    Write-Verbose " - $relativePath - $($skipTest.Matches.Groups['Reason'].Value)" -Verbose
                    continue
                }
                $Ast = [System.Management.Automation.Language.Parser]::ParseFile($filePath, [ref]$null, [ref]$null)
                $tokens = $Ast.FindAll( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] } , $true )
                $functionName = $tokens.Name
                # If the file contains a function and the function name is not in the test files, add it as an issue.
                if ($functionName.count -eq 1 -and $functionsInTestFiles -notcontains $functionName) {
                    $issues += " - $relativePath - $functionName"
                }
            }
            $issues -join [Environment]::NewLine |
                Should -BeNullOrEmpty -Because 'a test should exist for each of the functions in the module'
        }

        It "Should not contain '-Verbose' unless it is disabled using ':`$false' qualifier after it (ID: Verbose)" {
            $issues = @('')
            $scriptFiles | ForEach-Object {
                $filePath = $_.FullName
                $relativePath = $filePath.Replace($Path, '').Trim('\').Trim('/')
                $skipTest = Select-String -Path $filePath -Pattern '#SkipTest:(?<Type>.+):(?<Reason>.+)' -AllMatches
                if ($skipTest.Matches.Count -gt 0 -and $skipTest.Matches.Groups['Type'].Value -eq 'Verbose') {
                    Write-Verbose " - $relativePath - $($skipTest.Matches.Groups['Reason'].Value)" -Verbose
                    continue
                }
                Select-String -Path $filePath -Pattern '\s(-Verbose(?::\$true)?)\b(?!:\$false)' -AllMatches | ForEach-Object {
                    $issues += " - $relativePath`:L$($_.LineNumber) - $($_.Line)"
                }
            }
            $issues -join [Environment]::NewLine |
                Should -BeNullOrEmpty -Because "the script should not contain '-Verbose' unless it is disabled using ':`$false' qualifier after it."
        }

        It "Should use '`$null = ...' instead of '... | Out-Null' (ID: OutNull)" {
            $issues = @('')
            $scriptFiles | ForEach-Object {
                $filePath = $_.FullName
                $relativePath = $filePath.Replace($Path, '').Trim('\').Trim('/')
                $skipTest = Select-String -Path $filePath -Pattern '#SkipTest:(?<Type>.+):(?<Reason>.+)' -AllMatches
                if ($skipTest.Matches.Count -gt 0 -and $skipTest.Matches.Groups['Type'].Value -eq 'OutNull') {
                    Write-Verbose " - $relativePath - $($skipTest.Matches.Groups['Reason'].Value)" -Verbose
                    continue
                }
                Select-String -Path $filePath -Pattern 'Out-Null' -AllMatches | ForEach-Object {
                    $issues += " - $relativePath`:L$($_.LineNumber) - $($_.Line)"
                }
            }
            $issues -join [Environment]::NewLine |
                Should -BeNullOrEmpty -Because "the script should use '`$null = ...' instead of '... | Out-Null'"
        }

        It 'Should not use ternary operations for compatability reasons (ID: NoTernary)' -Skip {
            $issues = @('')
            $scriptFiles | ForEach-Object {
                $filePath = $_.FullName
                $relativePath = $filePath.Replace($Path, '').Trim('\').Trim('/')
                $skipTest = Select-String -Path $filePath -Pattern '#SkipTest:(?<Type>.+):(?<Reason>.+)' -AllMatches
                if ($skipTest.Matches.Count -gt 0 -and $skipTest.Matches.Groups['Type'].Value -eq 'NoTernary') {
                    Write-Verbose " - $relativePath - $($skipTest.Matches.Groups['Reason'].Value)" -Verbose
                    continue
                }
                Select-String -Path $filePath -Pattern '(?<!\|)\s+\?\s' -AllMatches | ForEach-Object {
                    $issues += " - $relativePath`:L$($_.LineNumber) - $($_.Line)"
                }
            }
            $issues -join [Environment]::NewLine |
                Should -BeNullOrEmpty -Because 'the script should not use ternary operations for compatability with PS 5.1 and below'
        }

        It 'all powershell keywords are lowercase (ID: LowercaseKeywords)' {
            $issues = @('')
            $scriptFiles | ForEach-Object {
                $filePath = $_.FullName
                $relativePath = $filePath.Replace($Path, '').Trim('\').Trim('/')
                $skipTest = Select-String -Path $filePath -Pattern '#SkipTest:(?<Type>.+):(?<Reason>.+)' -AllMatches
                if ($skipTest.Matches.Count -gt 0 -and $skipTest.Matches.Groups['Type'].Value -eq 'LowercaseKeywords') {
                    Write-Verbose " - $relativePath - $($skipTest.Matches.Groups['Reason'].Value)" -Verbose
                    continue
                }

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

        It 'Should have [CmdletBinding()] attribute (ID: CmdletBinding)' {
            $issues = @('')
            $functionFiles | ForEach-Object {
                $found = $false
                $filePath = $_.FullName
                $relativePath = $filePath.Replace($Path, '').Trim('\').Trim('/')
                $skipTest = Select-String -Path $filePath -Pattern '#SkipTest:(?<Type>.+):(?<Reason>.+)' -AllMatches
                if ($skipTest.Matches.Count -gt 0 -and $skipTest.Matches.Groups['Type'].Value -eq 'CmdletBinding') {
                    Write-Verbose " - $relativePath - $($skipTest.Matches.Groups['Reason'].Value)" -Verbose
                    continue
                }
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

        It 'Should have a param() block (ID: ParamBlock)' {
            $issues = @('')
            $functionFiles | ForEach-Object {
                $found = $false
                $filePath = $_.FullName
                $relativePath = $filePath.Replace($Path, '').Trim('\').Trim('/')
                $skipTest = Select-String -Path $filePath -Pattern '#SkipTest:(?<Type>.+):(?<Reason>.+)' -AllMatches
                if ($skipTest.Matches.Count -gt 0 -and $skipTest.Matches.Groups['Type'].Value -eq 'ParamBlock') {
                    Write-Verbose " - $relativePath - $($skipTest.Matches.Groups['Reason'].Value)" -Verbose
                    continue
                }
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
        It "Should use '[System.Environment]::ProcessorCount' instead of '`$env:NUMBER_OF_PROCESSORS' (ID: NumberOfProcessors)" {
            $issues = @('')
            $scriptFiles | ForEach-Object {
                Select-String -Path $_.FullName -Pattern '\$env:NUMBER_OF_PROCESSORS' -AllMatches | ForEach-Object {
                    $filePath = $_.FullName
                    $relativePath = $filePath.Replace($Path, '').Trim('\').Trim('/')
                    $skipTest = Select-String -Path $filePath -Pattern '#SkipTest:(?<Type>.+):(?<Reason>.+)' -AllMatches
                    if ($skipTest.Matches.Count -gt 0 -and $skipTest.Matches.Groups['Type'].Value -eq 'NumberOfProcessors') {
                        Write-Verbose " - $relativePath - $($skipTest.Matches.Groups['Reason'].Value)" -Verbose
                        continue
                    }
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
