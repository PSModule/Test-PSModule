[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter', 'Path',
    Justification = 'Path is being used.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter', 'SettingsFilePath',
    Justification = 'SettingsFilePath is being used.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments', 'relativeSettingsFilePath',
    Justification = 'relativeSettingsFilePath is being used.'
)]
[CmdLetBinding()]
Param(
    [Parameter(Mandatory)]
    [string] $Path,

    [Parameter(Mandatory)]
    [string] $SettingsFilePath
)

BeforeDiscovery {
    $ruleCollection = @{
        Error       = [Collections.Generic.List[hashtable]]::new()
        Warning     = [Collections.Generic.List[hashtable]]::new()
        Information = [Collections.Generic.List[hashtable]]::new()
    }
    'Error', 'Warning', 'Information' | ForEach-Object {
        $Severity = $_
        Get-ScriptAnalyzerRule -Severity $Severity | Sort-Object -Property Name | ForEach-Object {
            $rule = $_
            $ruleCollection[$Severity].Add(
                [ordered]@{
                    RuleName    = $rule.RuleName
                    CommonName  = $rule.CommonName
                    Description = $rule.Description
                }
            )
        }
    }

    $relativeSettingsFilePath = $SettingsFilePath.Replace($PSScriptRoot, '').Trim('\').Trim('/')
}

Describe "PSScriptAnalyzer tests using settings file [$relativeSettingsFilePath]" {
    Context '<_.key>' -ForEach $ruleCollection {
        It '<CommonName> (<RuleName>)' -ForEach $_.Value {

        }
    }
}


#         $severity = $_
#         $rules = $ruleCollection[$severity]
#         It "<Severity> rules" -ForEach $rules {
#             $ruleName = $_.RuleName
#             $commonName = $_.CommonName
#             $description = $_.Description
#             It "<CommonName> (<RuleName>)" {
#                 $testResults = Invoke-ScriptAnalyzer -Path $Path -Settings $SettingsFilePath -IncludeRule $ruleName
#                 $testResults | Should -BeNullOrEmpty
#             }
#         }
#     }
#     It '<CommonName> (<RuleName>)' -ForEach $rules {
#         $issues = @('')
#         $issues += $testResults | Where-Object -Property RuleName -EQ $ruleName | ForEach-Object {
#             $relativePath = $_.ScriptPath.Replace($Path, '').Trim('\').Trim('/')
#             " - $relativePath`:L$($_.Line):C$($_.Column): $($_.Message)"
#         }
#         if ($issues.Count -gt 1) {
#             $issues[0] = "[$($issues.Count - 1)] issues found:"
#         }
#         $issues -join [Environment]::NewLine | Should -BeNullOrEmpty
#     }
# }
