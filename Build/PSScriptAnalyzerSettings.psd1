# PSScriptAnalyzerSettings.psd1
# Settings for PSScriptAnalyzer invocation.
@{
    Rules = @{
        PSUseCompatibleCommands = @{
            Enable = $true
            TargetProfiles = @(
                'win-48_x64_10.0.17763.0_6.1.3_x64_4.0.30319.42000_core'
            )
            IgnoreCommands = @(
                'Invoke-Pester'
                'InModuleScope'
                'Describe'
                'Context'
                'It'
                'Should'
                'Mock'
                'Assert-VerifiableMock'
                'Assert-MockCalled'
            )
        }
        PSUseCompatibleSyntax = @{
            Enable = $true

            TargetVersions = @(
                '5.1',
                '6.2'
            )
        }
        PSUseCompatibleTypes = @{
            Enable = $true
            TargetProfiles = @(
                'win-48_x64_10.0.17763.0_6.1.3_x64_4.0.30319.42000_core'
            )
        }
        PSProvideCommentHelp = @{
            Enable = $true
            ExportedOnly = $true
            Placement = "begin"
        }
    }
}
