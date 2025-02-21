[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter', '',
    Justification = 'Parameters are used in the test.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments', 'functionBearingPublicFiles',
    Justification = 'Variables are used in the test.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments', 'functionBearingFiles',
    Justification = 'Variables are used in the test.'
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
    LogGroup " - Script files [$($scriptFiles.Count)]" {
        $scriptFiles | ForEach-Object {
            Write-Host " - $($_.FullName)"
        }
    }
    $functionsPath = Join-Path -Path $Path -ChildPath 'functions'
    $functionFiles = (Test-Path -Path $functionsPath) ? (Get-ChildItem -Path $functionsPath -File -Filter '*.ps1' -Recurse) : $null
    LogGroup " - Function files [$($functionFiles.Count)]" {
        $functionFiles | ForEach-Object {
            Write-Host " - $($_.FullName)"
        }
    }
    $privateFunctionsPath = Join-Path -Path $functionsPath -ChildPath 'private'
    $privateFunctionFiles = (Test-Path -Path $privateFunctionsPath) ?
        (Get-ChildItem -Path $privateFunctionsPath -File -Filter '*.ps1' -Recurse) : $null
    LogGroup " - Private function files [$($privateFunctionFiles.Count)]" {
        $privateFunctionFiles | ForEach-Object {
            Write-Host " - $($_.FullName)"
        }
    }
    $publicFunctionsPath = Join-Path -Path $functionsPath -ChildPath 'public'
    $publicFunctionFiles = (Test-Path -Path $publicFunctionsPath) ? (Get-ChildItem -Path $publicFunctionsPath -File -Filter '*.ps1' -Recurse) : $null
    LogGroup " - Public function files [$($publicFunctionFiles.Count)]" {
        $publicFunctionFiles | ForEach-Object {
            Write-Host " - $($_.FullName)"
        }
    }
    $variablesPath = Join-Path -Path $Path -ChildPath 'variables'
    $variableFiles = (Test-Path -Path $variablesPath) ? (Get-ChildItem -Path $variablesPath -File -Filter '*.ps1' -Recurse) : $null
    LogGroup " - Variable files [$($variableFiles.Count)]" {
        $variableFiles | ForEach-Object {
            Write-Host " - $($_.FullName)"
        }
    }
    $privateVariablesPath = Join-Path -Path $variablesPath -ChildPath 'private'
    $privateVariableFiles = (Test-Path -Path $privateVariablesPath) ?
        (Get-ChildItem -Path $privateVariablesPath -File -Filter '*.ps1' -Recurse) : $null
    LogGroup " - Private variable files [$($privateVariableFiles.Count)]" {
        $privateVariableFiles | ForEach-Object {
            Write-Host " - $($_.FullName)"
        }
    }
    $publicVariablesPath = Join-Path -Path $variablesPath -ChildPath 'public'
    $publicVariableFiles = (Test-Path -Path $publicVariablesPath) ?
        (Get-ChildItem -Path $publicVariablesPath -File -Filter '*.ps1' -Recurse) : $null
    LogGroup " - Public variable files [$($publicVariableFiles.Count)]" {
        $publicVariableFiles | ForEach-Object {
            Write-Host " - $($_.FullName)"
        }
    }
    $classPath = Join-Path -Path $Path -ChildPath 'classes'
    $classFiles = (Test-Path -Path $classPath) ? (Get-ChildItem -Path $classPath -File -Filter '*.ps1' -Recurse) : $null
    LogGroup " - Class files [$($classFiles.Count)]" {
        $classFiles | ForEach-Object {
            Write-Host " - $($_.FullName)"
        }
    }
    $privateClassPath = Join-Path -Path $classPath -ChildPath 'private'
    $privateClassFiles = (Test-Path -Path $privateClassPath) ?
        (Get-ChildItem -Path $privateClassPath -File -Filter '*.ps1' -Recurse) : $null
    LogGroup " - Private class files [$($privateClassFiles.Count)]" {
        $privateClassFiles | ForEach-Object {
            Write-Host " - $($_.FullName)"
        }
    }
    $publicClassPath = Join-Path -Path $classPath -ChildPath 'public'
    $publicClassFiles = (Test-Path -Path $publicClassPath) ?
        (Get-ChildItem -Path $publicClassPath -File -Filter '*.ps1' -Recurse) : $null
    LogGroup " - Public class files [$($publicClassFiles.Count)]" {
        $publicClassFiles | ForEach-Object {
            Write-Host " - $($_.FullName)"
        }
    }
    $testFiles = Get-ChildItem -Path $TestsPath -Include *.Tests.ps1 -Recurse -File
    LogGroup " - Test files [$($testFiles.Count)]" {
        $testFiles | ForEach-Object {
            Write-Host " - $($_.FullName)"
        }
    }
}

Describe 'PSModule - SourceCode tests' {
    Context 'General tests' {
        It "Should use '[System.Environment]::ProcessorCount' instead of '`$env:NUMBER_OF_PROCESSORS' (ID: NumberOfProcessors)" {
            $issues = @('')
            $scriptFiles | ForEach-Object {
                Select-String -Path $_.FullName -Pattern '\$env:NUMBER_OF_PROCESSORS' -AllMatches | ForEach-Object {
                    $filePath = $_.FullName
                    $relativePath = $filePath.Replace($Path, '').Trim('\').Trim('/')
                    $skipTest = Select-String -Path $filePath -Pattern '#SkipTest:NumberOfProcessors:(?<Reason>.+)' -AllMatches
                    if ($skipTest.Matches.Count -gt 0) {
                        $skipReason = $skipTest.Matches.Groups | Where-Object { $_.Name -eq 'Reason' } | Select-Object -ExpandProperty Value
                        Write-GitHubWarning -Message " - $relativePath - $skipReason" -Title 'Skipping NumberOfProcessors test'
                    } else {
                        $issues += " - $($_.Path):L$($_.LineNumber)"
                    }
                }
            }
            $issues -join [Environment]::NewLine |
                Should -BeNullOrEmpty -Because 'the script should use [System.Environment]::ProcessorCount instead of $env:NUMBER_OF_PROCESSORS'
        }
        It "Should not contain '-Verbose' unless it is disabled using ':`$false' qualifier after it (ID: Verbose)" {
            $issues = @('')
            $scriptFiles | ForEach-Object {
                $filePath = $_.FullName
                $relativePath = $filePath.Replace($Path, '').Trim('\').Trim('/')
                $skipTest = Select-String -Path $filePath -Pattern '#SkipTest:Verbose:(?<Reason>.+)' -AllMatches
                if ($skipTest.Matches.Count -gt 0) {
                    $skipReason = $skipTest.Matches.Groups | Where-Object { $_.Name -eq 'Reason' } | Select-Object -ExpandProperty Value
                    Write-GitHubWarning -Message " - $relativePath - $skipReason" -Title 'Skipping Verbose test'
                } else {
                    Select-String -Path $filePath -Pattern '\s(-Verbose(?::\$true)?)\b(?!:\$false)' -AllMatches | ForEach-Object {
                        $issues += " - $relativePath`:L$($_.LineNumber) - $($_.Line)"
                    }
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
                $skipTest = Select-String -Path $filePath -Pattern '#SkipTest:OutNull:(?<Reason>.+)' -AllMatches
                if ($skipTest.Matches.Count -gt 0) {
                    $skipReason = $skipTest.Matches.Groups | Where-Object { $_.Name -eq 'Reason' } | Select-Object -ExpandProperty Value
                    Write-GitHubWarning -Message " - $relativePath - $skipReason" -Title 'Skipping OutNull test'
                } else {
                    Select-String -Path $filePath -Pattern 'Out-Null' -AllMatches | ForEach-Object {
                        $issues += " - $relativePath`:L$($_.LineNumber) - $($_.Line)"
                    }
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
                $skipTest = Select-String -Path $filePath -Pattern '#SkipTest:NoTernary:(?<Reason>.+)' -AllMatches
                if ($skipTest.Matches.Count -gt 0) {
                    $skipReason = $skipTest.Matches.Groups | Where-Object { $_.Name -eq 'Reason' } | Select-Object -ExpandProperty Value
                    Write-GitHubWarning -Message " - $relativePath - $skipReason" -Title 'Skipping NoTernary test'
                } else {
                    Select-String -Path $filePath -Pattern '(?<!\|)\s+\?\s' -AllMatches | ForEach-Object {
                        $issues += " - $relativePath`:L$($_.LineNumber) - $($_.Line)"
                    }
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
                $skipTest = Select-String -Path $filePath -Pattern '#SkipTest:LowercaseKeywords:(?<Reason>.+)' -AllMatches
                if ($skipTest.Matches.Count -gt 0) {
                    $skipReason = $skipTest.Matches.Groups | Where-Object { $_.Name -eq 'Reason' } | Select-Object -ExpandProperty Value
                    Write-GitHubWarning -Message " - $relativePath - $skipReason" -Title 'Skipping LowercaseKeywords test'
                } else {
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
            }
            $issues -join [Environment]::NewLine | Should -BeNullOrEmpty -Because 'all powershell keywords should be lowercase'
        }
    }

    Context 'classes' {
    }

    Context 'functions' {
        Context 'Generic' {
            BeforeAll {
                $functionBearingFiles = $functionFiles | Where-Object {
                    $Ast = [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$null)
                    $tokens = $Ast.FindAll( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] } , $true )
                    $tokens.count -ne 0
                }
            }
            # It 'has synopsis for all functions' {}
            # It 'has description for all functions' {}
            # It 'has examples for all functions' {}
            # It 'comment based doc is indented with 8 spaces' {}
            # It 'boolean parameters in CmdletBinding() attribute are written without assignments' {}
            #     I.e. [CmdletBinding(ShouldProcess)] instead of [CmdletBinding(ShouldProcess = $true)]
            # It 'has [OutputType()] attribute' {}
            # Parameters
            # It 'comment based doc block start is indented with 4 spaces' {}
            # It 'has parameter description for all functions' {}
            # It 'parameters have [Parameter()] attribute' {}
            # It 'boolean parameters to the [Parameter()] attribute are written without assignments' {}
            #     I.e. [Parameter(Mandatory)] instead of [Parameter(Mandatory = $true)]
            # It 'datatype for parameters are written on the same line as the parameter name' {}
            # It 'datatype for parameters and parameter name are separated by a single space' {}
            # It 'parameters are separated by a blank line' {}
            It 'Should contain one function or filter (ID: FunctionCount)' {
                $issues = @('')
                $functionBearingFiles | ForEach-Object {
                    $filePath = $_.FullName
                    $relativePath = $filePath.Replace($Path, '').Trim('\').Trim('/')
                    $skipTest = Select-String -Path $filePath -Pattern '#SkipTest:FunctionCount:(?<Reason>.+)' -AllMatches
                    if ($skipTest.Matches.Count -gt 0) {
                        $skipReason = $skipTest.Matches.Groups | Where-Object { $_.Name -eq 'Reason' } | Select-Object -ExpandProperty Value
                        Write-GitHubWarning -Message " - $relativePath - $skipReason" -Title 'Skipping FunctionCount test'
                    } else {
                        $Ast = [System.Management.Automation.Language.Parser]::ParseFile($filePath, [ref]$null, [ref]$null)
                        $tokens = $Ast.FindAll( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] } , $true )
                        if ($tokens.count -ne 1) {
                            $issues += " - $relativePath - $($tokens.Name)"
                        }
                    }
                }
                $issues -join [Environment]::NewLine |
                    Should -BeNullOrEmpty -Because 'the script should contain one function or filter'
            }
            It 'Should have matching filename and function/filter name (ID: FunctionName)' {
                $issues = @('')
                $functionBearingFiles | ForEach-Object {
                    $filePath = $_.FullName
                    $fileName = $_.BaseName
                    $relativePath = $filePath.Replace($Path, '').Trim('\').Trim('/')
                    $skipTest = Select-String -Path $filePath -Pattern '#SkipTest:FunctionName:(?<Reason>.+)' -AllMatches
                    if ($skipTest.Matches.Count -gt 0) {
                        $skipReason = $skipTest.Matches.Groups | Where-Object { $_.Name -eq 'Reason' } | Select-Object -ExpandProperty Value
                        Write-GitHubWarning -Message " - $relativePath - $skipReason" -Title 'Skipping FunctionName test'
                    } else {
                        $Ast = [System.Management.Automation.Language.Parser]::ParseFile($filePath, [ref]$null, [ref]$null)
                        $tokens = $Ast.FindAll( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] } , $true )
                        if ($tokens.Name -ne $fileName) {
                            $issues += " - $relativePath - $($tokens.Name)"
                        }
                    }
                }
                $issues -join [Environment]::NewLine |
                    Should -BeNullOrEmpty -Because 'the script files should be called the same as the function they contain'
            }
            It 'Should have [CmdletBinding()] attribute (ID: CmdletBinding)' {
                $issues = @('')
                $functionBearingFiles | ForEach-Object {
                    $found = $false
                    $filePath = $_.FullName
                    $relativePath = $filePath.Replace($Path, '').Trim('\').Trim('/')
                    $skipTest = Select-String -Path $filePath -Pattern '#SkipTest:CmdletBinding:(?<Reason>.+)' -AllMatches
                    if ($skipTest.Matches.Count -gt 0) {
                        $skipReason = $skipTest.Matches.Groups | Where-Object { $_.Name -eq 'Reason' } | Select-Object -ExpandProperty Value
                        Write-GitHubWarning -Message " - $relativePath - $skipReason" -Title 'Skipping CmdletBinding test'
                    } else {
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
                }
                $issues -join [Environment]::NewLine |
                    Should -BeNullOrEmpty -Because 'the script should have [CmdletBinding()] attribute'
            }
            It 'Should have a param() block (ID: ParamBlock)' {
                $issues = @('')
                $functionBearingFiles | ForEach-Object {
                    $found = $false
                    $filePath = $_.FullName
                    $relativePath = $filePath.Replace($Path, '').Trim('\').Trim('/')
                    $skipTest = Select-String -Path $filePath -Pattern '#SkipTest:ParamBlock:(?<Reason>.+)' -AllMatches
                    if ($skipTest.Matches.Count -gt 0) {
                        $skipReason = $skipTest.Matches.Groups | Where-Object { $_.Name -eq 'Reason' } | Select-Object -ExpandProperty Value
                        Write-GitHubWarning -Message " - $relativePath - $skipReason" -Title 'Skipping ParamBlock test'
                    } else {
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
                }
                $issues -join [Environment]::NewLine |
                    Should -BeNullOrEmpty -Because 'the script should have a param() block'
            }
        }
        Context 'public functions' {
            BeforeAll {
                $functionBearingPublicFiles = $publicFunctionFiles | Where-Object {
                    $Ast = [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$null)
                    $tokens = $Ast.FindAll( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] } , $true )
                    $tokens.count -ne 0
                }
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
                $functionBearingPublicFiles | ForEach-Object {
                    $filePath = $_.FullName
                    $relativePath = $filePath.Replace($Path, '').Trim('\').Trim('/')
                    $skipTest = Select-String -Path $filePath -Pattern '#SkipTest:FunctionTest:(?<Reason>.+)' -AllMatches
                    if ($skipTest.Matches.Count -gt 0) {
                        $skipReason = $skipTest.Matches.Groups | Where-Object { $_.Name -eq 'Reason' } | Select-Object -ExpandProperty Value
                        Write-GitHubWarning -Message " - $relativePath - $skipReason" -Title 'Skipping FunctionTest test'
                    } else {
                        $Ast = [System.Management.Automation.Language.Parser]::ParseFile($filePath, [ref]$null, [ref]$null)
                        $tokens = $Ast.FindAll( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] } , $true )
                        $functionName = $tokens.Name
                        # If the file contains a function and the function name is not in the test files, add it as an issue.
                        if ($functionName.count -eq 1 -and $functionsInTestFiles -notcontains $functionName) {
                            $issues += " - $relativePath - $functionName"
                        }
                    }
                }
                $issues -join [Environment]::NewLine |
                    Should -BeNullOrEmpty -Because 'a test should exist for each of the functions in the module'
            }
        }
        Context 'private functions' {}
    }

    Context 'variables' {
    }

    Context 'Module manifest' {
        # It 'Module Manifest exists (maifest.psd1 or modulename.psd1)' {}
        # It 'Module Manifest is valid' {}
    }
}
