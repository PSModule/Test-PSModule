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
    $rules = [Collections.Generic.List[System.Collections.Specialized.OrderedDictionary]]::new()
    $ruleObjects = Get-ScriptAnalyzerRule | Sort-Object -Property Severity, CommonName
    foreach ($ruleObject in $ruleObjects) {
        $rules.Add(
            [ordered]@{
                RuleName    = $ruleObject.RuleName
                CommonName  = $ruleObject.CommonName
                Severity    = $ruleObject.Severity
                Description = $ruleObject.Description
            }
        )
    }
    Write-Warning "Discovered [$($rules.Count)] rules"
    $relativeSettingsFilePath = $SettingsFilePath.Replace($PSScriptRoot, '').Trim('\').Trim('/')
}

Describe "PSScriptAnalyzer tests using settings file [$relativeSettingsFilePath]" {
    BeforeAll {
        $testResults = Invoke-ScriptAnalyzer -Path $Path -Settings $SettingsFilePath -Recurse
        Write-Warning "Found [$($testResults.Count)] issues"
    }

    Context '<Severity>' -ForEach ($rules.Severity | Select-Object -Unique) {
        It '<CommonName> (<RuleName>)' -ForEach ($rules | Where-Object -Property Severity -EQ $Severity) {
            $issues = @('')
            $issues += $testResults | Where-Object -Property RuleName -EQ $ruleName | ForEach-Object {
                $relativePath = $_.ScriptPath.Replace($Path, '').Trim('\').Trim('/')
                " - $relativePath`:L$($_.Line):C$($_.Column): $($_.Message)"
            }
            if ($issues.Count -gt 1) {
                $issues[0] = "[$($issues.Count - 1)] issues found:"
            }
            $issues -join [Environment]::NewLine | Should -BeNullOrEmpty
        }
    }
}
