InModuleScope $ProjectName {
    . "$PSScriptRoot\..\TestUtils.ps1"

    Describe 'Get-CustomizationsArg' {
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
                Application          = @( 'notepad.exe', @{ Path = ('calc.exe', 'mspaint.exe') } )
                Wifi                 = @(
                    @{
                        Ssid = 'Kaguya-sama'
                    }
                    @{
                        Ssid        = 'Shirogane'
                        SecurityKey = 'Hayasake1234'
                        AutoConnect = $false
                    }
                )
                KioskXml = 'settings.xml'
            },
            @{
                ComputerName         = 'Dungeon'
                LocalAdminCredential = $localCred
                Application          = @(
                    @{
                        Name            = 'French Fries'
                        Path            = ('malware.exe', 'evil.exe', 'stuxnet.exe')
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
                Wifi                 = @{
                    Ssid        = 'Hinata'
                    AutoConnect = $true
                }
            }
        )

        $i = 0
        $results = $testCases | ForEach-Object -Process {
            $case = $_ | Copy-Hashtable
            $result = Get-CustomizationsArg @case
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
            Test-ObjectProperty -InputObject $Inputs.Application -OutputObject $Application -PropertyName 'Name'
        }

        It 'case <CaseIndex>: returns expected application commands' -TestCases $results {
            param($Application, $Inputs)
            Test-ObjectProperty -InputObject $Inputs.Application -OutputObject $Application -PropertyName 'Command'
        }

        It 'case <CaseIndex>: returns expected application "continue install" settings' -TestCases $results {
            param($Application, $Inputs)
            Test-ObjectProperty -InputObject $Inputs.Application -OutputObject $Application -PropertyName 'ContinueInstall'
        }

        It 'case <CaseIndex>: returns expected application "restart required" settings' -TestCases $results {
            param($Application, $Inputs)
            Test-ObjectProperty -InputObject $Inputs.Application -OutputObject $Application -PropertyName 'RestartRequired'
        }

        It 'case <CaseIndex>: returns expected application restart exit codes' -TestCases $results {
            param($Application, $Inputs)
            Test-ObjectProperty -InputObject $Inputs.Application -OutputObject $Application -PropertyName 'RestartExitCode'
        }

        It 'case <CaseIndex>: returns expected application success exit codes' -TestCases $results {
            param($Application, $Inputs)
            Test-ObjectProperty -InputObject $Inputs.Application -OutputObject $Application -PropertyName 'SuccessExitCode'
        }

        It 'case <CaseIndex>: returns expected number of Wi-Fi settings' -TestCases $results {
            param($Wifi, $Inputs)
            @($Wifi) | Should -HaveCount @($Inputs.Wifi).Count
        }

        It 'case <CaseIndex>: returns expected Wi-Fi SSID' -TestCases $results {
            param($Wifi, $Inputs)
            Test-ObjectProperty -InputObject $Inputs.Wifi -OutputObject $Wifi -PropertyName 'Ssid'
        }

        It 'case <CaseIndex>: returns expected Wi-Fi security type' -TestCases $results {
            param($Wifi, $Inputs)
            Test-ObjectProperty -InputObject $Inputs.Wifi -OutputObject $Wifi -PropertyName 'SecurityType'
        }

        It 'case <CaseIndex>: returns expected Wi-Fi security key' -TestCases $results {
            param($Wifi, $Inputs)
            Test-ObjectProperty -InputObject $Inputs.Wifi -OutputObject $Wifi -PropertyName 'SecurityKey'
        }

        It 'case <CaseIndex>: returns expected Wi-Fi auto-connect setting' -TestCases $results {
            param($Wifi, $Inputs)
            Test-ObjectProperty -InputObject $Inputs.Wifi -OutputObject $Wifi -PropertyName 'AutoConnect'
        }

        It 'case <CaseIndex>: returns expected kiosk XML path' -TestCases $results {
            param($KioskXml, $Inputs)
            $KioskXml | Should -Be $Inputs.KioskXml
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
            { Get-CustomizationsArg -ComputerName 'Desktop' -LocalAdminCredential $localCred -Application $app } |
            Should -Throw 'application is invalid'
        }

        It 'raises an error when the application path is missing' {
            { Get-CustomizationsArg -ComputerName '03' -LocalAdminCredential $localCred -Application @{ Name = 'Blender' } } |
            Should -Throw 'application path is missing'
        }

        It "raises an error when the application path can't be found" {
            Mock Test-Path { $false } -Verifiable -ParameterFilter { $Path -eq 'doesntexist.exe'; $PathType -eq 'Leaf' }
            { Get-CustomizationsArg -ComputerName '-' -LocalAdminCredential $localCred -Application 'doesntexist.exe' } |
            Should -Throw 'application "doesntexist.exe" cannot be found'
            Assert-MockCalled Test-Path -Scope It
        }

        It "raises an error when the Wi-Fi SSID is missing" {
            { Get-CustomizationsArg -ComputerName 'Skynet' -LocalAdminCredential $localCred -Wifi @{ SecurityKey = 'DontYouWish' } } |
            Should -Throw 'SSID is missing'
        }

        It "raises an error when the kiosk XML can't be found" {
            Mock Test-Path { $false } -Verifiable -ParameterFilter { $Path -eq 'doesntexist.xml'; $PathType -eq 'Leaf' }
            { Get-CustomizationsArg -ComputerName 'Macademia' -LocalAdminCredential $localCred -KioskXml 'doesntexist.xml' } |
            Should -Throw
        }
    }
}