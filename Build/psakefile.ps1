Properties {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]

    $ProjectRoot = $env:APPVEYOR_BUILD_FOLDER
    if (-not $ProjectRoot) {
        $ProjectRoot = Resolve-Path "$PSScriptRoot\.."
    }
    $ProjectName = Split-Path -Leaf -Path $ProjectRoot
    $ModuleRoot = "$ProjectRoot\$ProjectName"
    $ManifestPath = Join-Path -Path $ModuleRoot -ChildPath "$ProjectName.psd1"
    $TestFile = "$ProjectRoot\TestResults.xml"
    $CodeCoverageCompliancePercentage = 95
}

TaskSetup {
    Import-Module -Name $ModuleRoot -Force
}

task PreBuild -description 'Update Appveyor build version' {
    if ($env:APPVEYOR) {
        $version = (Get-Module $ProjectName).Version
        Update-AppveyorBuild -Version "$version.$env:APPVEYOR_BUILD_NUMBER"
    }
}

task Analyze -description 'Find common code issues' {
    $settingsPath = Join-Path -Path $ProjectRoot -ChildPath 'build\PSScriptAnalyzerSettings.psd1'
    $analyzerResults = Invoke-ScriptAnalyzer -Path $ModuleRoot -Recurse -ReportSummary -Settings $settingsPath
    if ($analyzerResults) {
        $analyzerResults | Format-Table
        throw "One or more PSScriptAnalyzer errors/warnings were found."
    }
}

task Test -description "Run the test suite" {
    $pesterParams = @{
        Script = "$ProjectRoot\Tests"
        Strict = $true
        PassThru = $true
        OutputFormat = 'NUnitXml'
        OutputFile = $TestFile
        CodeCoverage = (Get-ChildItem -Path "$ModuleRoot\*.ps1" -Exclude "*.Tests.*" -Recurse).FullName
    }
    if ($TestName) {
        $pesterParams.TestName = $TestName
        $pesterParams.Remove('CodeCoverage')
    }
    $testResults = Invoke-Pester @pesterParams
    if ($env:APPVEYOR) {
        $wc = New-Object 'System.Net.WebClient'
        $wc.UploadFile("https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)", (Resolve-Path $TestFile)) | Out-Null
    }
    Remove-Item $TestFile -Force -ErrorAction SilentlyContinue

    if ($testResults.CodeCoverage) {
        $overallCoverage = [Math]::Floor($testResults.CodeCoverage.NumberOfCommandsExecuted / $testResults.CodeCoverage.NumberOfCommandsAnalyzed * 100)
        Assert ($testResults.FailedCount -eq 0) "Failed '$($testResults.FailedCount)' tests, build failed"
        Assert ($overallCoverage -ge $CodeCoverageCompliancePercentage) `
            "A code coverage of $overallCoverage does not meet the build requirement of $CodeCoverageCompliancePercentage"
    }
}

task Build -depends PreBuild, Analyze, Test -description 'Update module manifest' {
    $manifestExports = (Get-Module -Name $ProjectName).ExportedFunctions.Keys
    $folderExports = (Get-ChildItem -Path "$ModuleRoot\Public\*.ps1").BaseName
    $newFunctions = $folderExports | Where-Object -FilterScript { $_ -notin $manifestExports }
    $deletedFunctions = $manifestExports | Where-Object -FilterScript { $_ -notin $folderExports }

    if ($newFunctions -or $deletedFunctions) {
        Update-ModuleManifest -Path $ManifestPath -FunctionsToExport $folderExports
    }
}

task Deploy -depends Build -description 'Publish the module to the PowerShell Gallery' {
    $env:APPVEYOR_REPO_BRANCH

    if ($env:APPVEYOR_REPO_BRANCH -ne 'master') { return }

    # Only deploy if the manifest has a newer version than the one on PSGallery
    $galleryModule = Find-Module -Name $ProjectName -ErrorAction SilentlyContinue
    $galleryVersion = $null
    [Version]::TryParse($galleryModule.Version, [ref]$galleryVersion) | Out-Null
    $moduleVersion = (Get-Module -Name $ProjectName).Version
    if ($galleryVersion -ge $moduleVersion) { return }

    Publish-Module -Path $ModuleRoot -NuGetApiKey $env:NuGetApiKey
}

task default -depends Build