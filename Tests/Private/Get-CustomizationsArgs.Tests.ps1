InModuleScope $ProjectName {
    . "$PSScriptRoot\..\TestUtils.ps1"

    Describe 'Get-CustomizationsArgs' {
        $doc1 = New-Object -TypeName System.Xml.XmlDocument
        $doc2 = New-Object -TypeName System.Xml.XmlDocument
        $doc1.LoadXml('<anime><title>Shirobako</title><characters><character>Aoi Miyamori</character></characters></anime>')
        $doc2.LoadXml('<books><book><title>A Tale of Two Cities</title></book><book><title>Bleak House</title></book></books>')
        Mock Resolve-Path { $Path }
        Mock Test-Path { $true }

        $testCases = @(
            @{
                ComputerName         = 'PC02'
                LocalAdminCredential = $localCred
                DomainName           = 'SquirrelCorp'
                DomainJoinCredential = $domainCred
                Application          = @{ Path = 'notepad.exe' }
            },
            @{
                ComputerName         = 'PC05'
                LocalAdminCredential = $localCred
                Application          = @( 'notepad.exe', @{ Path = 'calc.exe' } )
            },
            @{
                ComputerName         = 'Dungeon'
                LocalAdminCredential = $localCred
                Application          = @(
                    @{
                        Name            = 'French Fries'
                        Path            = 'malware.exe'
                        Command         = 'delete everything'
                        ContinueInstall = $false
                        RestartRequired = $true
                        RestartExitCode = 123
                        SuccessExitCode = 2
                    },
                    @{
                        Name = 'Fred Astair'
                        Path = 'dance.exe'
                    }
                )
            }
        )

        $i = 0
        $results = $testCases | ForEach-Object -Process {
            $case = $_ | Copy-Hashtable
            $result = Get-CustomizationsArgs @case
            $result.CaseIndex = ++$i
            $result.Inputs = $case
            $result
        }

        It 'case <CaseIndex>: returns expected computer name' -TestCases $results {
            param($ComputerName, $Inputs)
            $ComputerName | Should -Be $Inputs.ComputerName
        }

        It 'case <CaseIndex>: returns expected local admin credential' -TestCases $results {
            param($LocalAdminCredential, $Inputs)
            $LocalAdminCredential | Should -Be $Inputs.LocalAdminCredential
        }

        It 'case <CaseIndex>: returns expected domain name' -TestCases $results {
            param($DomainName, $Inputs)
            $DomainName | Should -Be $Inputs.DomainName
        }

        It 'case <CaseIndex>: returns expected domain join credential' -TestCases $results {
            param($DomainJoinCredential, $Inputs)
            $DomainJoinCredential | Should -Be $Inputs.DomainJoinCredential
        }

        It 'case <CaseIndex>: returns expected number of applications' -TestCases $results {
            param($Application, $Inputs)
            @($Application) | Should -HaveCount @($Inputs.Application).Count
        }

        It 'case <CaseIndex>: returns expected application names' -TestCases $results {
            param($Application, $Inputs)
            Test-ApplicationProperty -InApp $Inputs.Application -OutApp $Application -PropertyName 'Name'
        }

        It 'case <CaseIndex>: returns expected application paths' -TestCases $results {
            param($Application, $Inputs)
            Test-ApplicationProperty -InApp $Inputs.Application -OutApp $Application -PropertyName 'Path'
        }

        It 'case <CaseIndex>: returns expected application commands' -TestCases $results {
            param($Application, $Inputs)
            Test-ApplicationProperty -InApp $Inputs.Application -OutApp $Application -PropertyName 'Command'
        }

        It 'case <CaseIndex>: returns expected application "continue install" settings' -TestCases $results {
            param($Application, $Inputs)
            Test-ApplicationProperty -InApp $Inputs.Application -OutApp $Application -PropertyName 'ContinueInstall'
        }

        It 'case <CaseIndex>: returns expected application "restart required" settings' -TestCases $results {
            param($Application, $Inputs)
            Test-ApplicationProperty -InApp $Inputs.Application -OutApp $Application -PropertyName 'RestartRequired'
        }

        It 'case <CaseIndex>: returns expected application restart exit codes' -TestCases $results {
            param($Application, $Inputs)
            Test-ApplicationProperty -InApp $Inputs.Application -OutApp $Application -PropertyName 'RestartExitCode'
        }

        It 'case <CaseIndex>: returns expected application success exit codes' -TestCases $results {
            param($Application, $Inputs)
            Test-ApplicationProperty -InApp $Inputs.Application -OutApp $Application -PropertyName 'SuccessExitCode'
        }

        $invalidApplicationCases = @(
            @{
                app = 42
            },
            @{
                app = $false
            }
        )
        It 'raises an error when application is invalid (<Application>)' -TestCases $invalidApplicationCases {
            param($app)
            { Get-CustomizationsArgs -ComputerName 'Desktop' -LocalAdminCredential $localCred -Application $app } |
            Should -Throw 'application is invalid'
        }

        It 'raises an error when the application path is missing' {
            { Get-CustomizationsArgs -ComputerName '03' -LocalAdminCredential $localCred -Application @{ Name = 'Blender' } } |
            Should -Throw 'application path is missing'
        }

        It "raises an error when the application path can't be found" {
            Mock Test-Path { $false } -Verifiable -ParameterFilter { $Path -eq 'doesntexist.exe'; $PathType -eq 'Leaf' }
            { Get-CustomizationsArgs -ComputerName '-' -LocalAdminCredential $localCred -Application 'doesntexist.exe' } |
            Should -Throw 'application "doesntexist.exe" cannot be found'
            Assert-MockCalled Test-Path -Scope It
        }
    }

}