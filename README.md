# Test-PSModule

Tests PowerShell module repos using PSModule framework rules.

This GitHub Action is a part of the [PSModule framework](https://github.com/PSModule). It is recommended to use the
[Process-PSModule workflow](https://github.com/PSModule/Process-PSModule) to automate the whole process of managing the PowerShell module.

## Specifications and practices

Test-PSModule enables:

- [Test-Driven Development](https://testdriven.io/test-driven-development/) using [Pester](https://pester.dev) via [Invoke-Pester](https://github.com/PSModule/Invoke-Pester).

## How it works

- The action runs test on the module repository based on `Settings`:
  - `SourceCode` - Tests source code style and standards based on PSModule framework rules.
  - `Module` - Tests the module build module style and standards based on PSModule framework rules.
    - The module is imported in its own context to avoid conflicts with other modules.
- The action returns the test results as action [outputs](#outputs).
- The following reports are calculated and uploaded as artifacts. This is done to support the action being run in matrix jobs.
  - Test suite results. In [Process-PSModule](https://github.com/PSModule/Process-PSModule) this is evaluated in a later job by [Get-PesterTestResults](https://github.com/PSModule/Get-PesterTestResults)
  - Code coverage results. In [Process-PSModule](https://github.com/PSModule/Process-PSModule) this is evaluated in a later job by [Get-PesterCodeCoverage](https://github.com/PSModule/Get-PesterCodeCoverage)

The action fails if any of the tests fail or it fails to run the tests.
This is mitigated by the `continue-on-error` option in the workflow.

## How to use it

It is recommended to use the [Process-PSModule workflow](https://github.com/PSModule/Process-PSModule) to automate the whole process of managing the PowerShell module.

To use the action, create a new file in the `.github/workflows` directory of the module repository and add the following content.
<details>
<summary>Workflow suggestion - before module is built</summary>

```yaml
name: Test-PSModule

on: [push]

jobs:
  Test-PSModule:
    name: Test-PSModule
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repo
        uses: actions/checkout@v4

      - name: Initialize environment
        uses: PSModule/Initialize-PSModule@main

      - name: Test-PSModule
        uses: PSModule/Test-PSModule@main
        with:
          Settings: SourceCode

```
</details>

<details>
<summary>Workflow suggestion - after module is built</summary>

```yaml
name: Test-PSModule

on: [push]

jobs:
  Test-PSModule:
    name: Test-PSModule
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repo
        uses: actions/checkout@v4

      - name: Initialize environment
        uses: PSModule/Initialize-PSModule@main

      - name: Test-PSModule
        uses: PSModule/Test-PSModule@main
        with:
          Settings: Module

```
</details>

## Usage

### Inputs

| Name | Description | Required | Default |
| ---- | ----------- | -------- | ------- |
| `Name` | The name of the module to test. The name of the repository is used if not specified. | `false` | |
| `Settings` | The type of tests to run. Can be either `Module` or `SourceCode`.  | `true` | |
| `Debug` | Enable debug output. | `false` | `'false'` |
| `Verbose` | Enable verbose output. | `false` | `'false'` |
| `Version` | Specifies the version of the GitHub module to be installed. The value must be an exact version. | `false` | |
| `Prerelease` | Allow prerelease versions if available. | `false` | `'false'` |
| `WorkingDirectory` | The working directory to use for the action. This is the root folder where tests and outputs are expected. | `false` | `'.'` |
| `StepSummary_Mode`                   | Controls which tests to show in the GitHub step summary. Allows "Full" (all tests), "Failed" (only failed tests), or "None" (disable step summary). | `false` | `Failed` |
| `StepSummary_ShowTestOverview`       | Controls whether to show the test overview table in the GitHub step summary.                                                                        | `false` | `false`  |
| `StepSummary_ShowConfiguration`      | Controls whether to show the configuration details in the GitHub step summary.                                                                      | `false` | `false`  |
| `Run_ExcludePath`                    | Directories/files to exclude from the run.                                                                                                          | `false` |          |
| `Run_ScriptBlock`                    | ScriptBlocks containing tests to be executed.                                                                                                       | `false` |          |
| `Run_Container`                      | ContainerInfo objects containing tests to be executed.                                                                                              | `false` |          |
| `Run_TestExtension`                  | Filter used to identify test files (e.g. `.Tests.ps1`).                                                                                             | `false` |          |
| `Run_Exit`                           | Whether to exit with a non-zero exit code on failure.                                                                                               | `false` |          |
| `Run_Throw`                          | Whether to throw an exception on test failure.                                                                                                      | `false` |          |
| `Run_SkipRun`                        | Discovery only, skip actual test run.                                                                                                               | `false` |          |
| `Run_SkipRemainingOnFailure`         | Skips remaining tests after the first failure. Options: `None`, `Run`, `Container`, `Block`.                                                        | `false` |          |
| `Filter_Tag`                         | Tags of Describe/Context/It blocks to run.                                                                                                          | `false` |          |
| `Filter_ExcludeTag`                  | Tags of Describe/Context/It blocks to exclude.                                                                                                      | `false` |          |
| `Filter_Line`                        | Filter by file + scriptblock start line (e.g. `C:\tests\file1.Tests.ps1:37`).                                                                       | `false` |          |
| `Filter_ExcludeLine`                 | Exclude by file + scriptblock start line. Precedence over `Filter_Line`.                                                                            | `false` |          |
| `Filter_FullName`                    | Full name of a test with wildcards, joined by dot. E.g. `*.describe Get-Item.test1`                                                                 | `false` |          |
| `CodeCoverage_Enabled`               | Enable code coverage.                                                                                                                               | `false` |          |
| `CodeCoverage_OutputFormat`          | Format for the coverage report. Possible values: `JaCoCo`, `CoverageGutters`, `Cobertura`.                                                          | `false` |          |
| `CodeCoverage_OutputPath`            | Where to save the code coverage report (relative to the current dir).                                                                               | `false` |          |
| `CodeCoverage_OutputEncoding`        | Encoding of the coverage file.                                                                                                                      | `false` |          |
| `CodeCoverage_Path`                  | Files/directories to measure coverage on (by default, reuses `Path` from the general settings).                                                     | `false` |          |
| `CodeCoverage_ExcludeTests`          | Exclude tests themselves from coverage.                                                                                                             | `false` |          |
| `CodeCoverage_RecursePaths`          | Recurse through coverage directories.                                                                                                               | `false` |          |
| `CodeCoverage_CoveragePercentTarget` | Desired minimum coverage percentage.                                                                                                                | `false` |          |
| `CodeCoverage_UseBreakpoints`        | **Experimental**: When `false`, use a Profiler-based tracer instead of breakpoints.                                                                 | `false` |          |
| `CodeCoverage_SingleHitBreakpoints`  | Remove breakpoints after first hit.                                                                                                                 | `false` |          |
| `TestResult_Enabled`                 | Enable test-result output (e.g. NUnitXml, JUnitXml).                                                                                                | `false` |          |
| `TestResult_OutputFormat`            | Possible values: `NUnitXml`, `NUnit2.5`, `NUnit3`, `JUnitXml`.                                                                                      | `false` |          |
| `TestResult_OutputPath`              | Where to save the test-result report (relative path).                                                                                               | `false` |          |
| `TestResult_OutputEncoding`          | Encoding of the test-result file.                                                                                                                   | `false` |          |
| `Should_ErrorAction`                 | Controls if `Should` throws on error. Use `Stop` to throw, or `Continue` to fail at the end.                                                        | `false` |          |
| `Debug_ShowFullErrors`               | Show Pester internal stack on errors. (Deprecated – overrides `Output.StackTraceVerbosity` to `Full`).                                              | `false` |          |
| `Debug_WriteDebugMessages`           | Write debug messages to screen.                                                                                                                     | `false` |          |
| `Debug_WriteDebugMessagesFrom`       | Filter debug messages by source. Wildcards allowed.                                                                                                 | `false` |          |
| `Debug_ShowNavigationMarkers`        | Write paths after every block/test for easy navigation in Visual Studio Code.                                                                       | `false` |          |
| `Debug_ReturnRawResultObject`        | Returns an unfiltered result object, for development only.                                                                                          | `false` |          |
| `Output_Verbosity`                   | Verbosity: `None`, `Normal`, `Detailed`, `Diagnostic`.                                                                                              | `false` |          |
| `Output_StackTraceVerbosity`         | Stacktrace detail: `None`, `FirstLine`, `Filtered`, `Full`.                                                                                         | `false` |          |
| `Output_CIFormat`                    | CI format of error output: `None`, `Auto`, `AzureDevops`, `GithubActions`.                                                                          | `false` |          |
| `Output_CILogLevel`                  | CI log level: `Error` or `Warning`.                                                                                                                 | `false` |          |
| `Output_RenderMode`                  | How to render console output: `Auto`, `Ansi`, `ConsoleColor`, `Plaintext`.                                                                          | `false` |          |
| `TestDrive_Enabled`                  | Enable `TestDrive`.                                                                                                                                 | `false` |          |
| `TestRegistry_Enabled`               | Enable `TestRegistry`.                                                                                                                              | `false` |          |

### Outputs

| Output                  | Description                          |
|-------------------------|--------------------------------------|
| `Outcome`               | Outcome of the test run.             |
| `Conclusion`            | Conclusion status of test execution. |
| `Executed`              | Indicates if tests were executed.    |
| `Result`                | Overall result (`Passed`, `Failed`). |
| `FailedCount`           | Number of failed tests.              |
| `FailedBlocksCount`     | Number of failed blocks.             |
| `FailedContainersCount` | Number of failed containers.         |
| `PassedCount`           | Number of passed tests.              |
| `SkippedCount`          | Number of skipped tests.             |
| `InconclusiveCount`     | Number of inconclusive tests.        |
| `NotRunCount`           | Number of tests not run.             |
| `TotalCount`            | Total tests executed.                |

## PSModule tests

### SourceCode tests

The [PSModule - SourceCode tests](./scripts/tests/SourceCode/PSModule/PSModule.Tests.ps1) verifies the following coding practices that the framework enforces:

| ID                  | Category            | Description                                                                                |
|---------------------|---------------------|--------------------------------------------------------------------------------------------|
| NumberOfProcessors  | General             | Should use `[System.Environment]::ProcessorCount` instead of `$env:NUMBER_OF_PROCESSORS`.  |
| Verbose             | General             | Should not contain `-Verbose` unless it is explicitly disabled with `:$false`.             |
| OutNull             | General             | Should use `$null = ...` instead of piping output to `Out-Null`.                           |
| NoTernary           | General             | Should not use ternary operations to maintain compatibility with PowerShell 5.1 and below. |
| LowercaseKeywords   | General             | All PowerShell keywords should be written in lowercase.                                    |
| FunctionCount       | Functions (Generic) | Each script file should contain exactly one function or filter.                            |
| FunctionName        | Functions (Generic) | Script filenames should match the name of the function or filter they contain.             |
| CmdletBinding       | Functions (Generic) | Functions should include the `[CmdletBinding()]` attribute.                                |
| ParamBlock          | Functions (Generic) | Functions should have a parameter block (`param()`).                                       |
| FunctionTest        | Functions (Public)  | All public functions/filters should have corresponding tests.                              |

### Module tests

The [PSModule - Module tests](./scripts/tests/Module/PSModule/PSModule.Tests.ps1) verifies the following coding practices that the framework enforces:

| Name | Description |
| ------ | ----------- |
| Module Manifest exists | Verifies that a module manifest file is present. |
| Module Manifest is valid | Verifies that the module manifest file is valid. |
