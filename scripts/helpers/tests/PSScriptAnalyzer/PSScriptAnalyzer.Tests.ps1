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
    $rules = Get-ScriptAnalyzerRule | Sort-Object -Property Severity -Verbose:$false | ConvertTo-Json | ConvertFrom-Json -AsHashtable
    Write-Warning "Discovered [$($rules.Count)] rules"
    $relativeSettingsFilePath = $SettingsFilePath.Replace($PSScriptRoot, '').Trim('\').Trim('/')
}

Describe "PSScriptAnalyzer tests using settings file [$relativeSettingsFilePath]" {
    BeforeAll {
        $testResults = Invoke-ScriptAnalyzer -Path $Path -Settings $SettingsFilePath -Recurse -Verbose:$false
        Write-Warning "Found [$($testResults.Count)] issues"
    }

    It '<CommonName> (<RuleName>)' -ForEach $rules {
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
