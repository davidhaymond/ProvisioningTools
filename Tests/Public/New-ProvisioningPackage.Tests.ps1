InModuleScope $ProjectName {
    . "$PSScriptRoot\..\TestUtils.ps1"

    Describe 'New-ProvisioningPackage' {
        $localCred = Get-CredentialFromPlainText -UserName 'Admin' -Password 'wow_wow_wow'
        $domainCred = Get-CredentialFromPlainText -UserName 'Joiner' -Password 'FBI-secrecy*'
        $fakeGuid = '12345678-9012-3456-7890-123456789012'
        $fakeXmlPath = Join-Path -Path $env:TEMP -ChildPath "$fakeGuid.xml"

        $params1 = @{
            LocalAdminCredential = $localCred
            DomainName           = 'Musashino'
            DomainJoinCredential = $domainCred
            Application          = @('explorer.exe', @{ Path = 'test.exe'; RestartRequired = $true })
            Path                 = 'C:\test'
        }
        $params2 = @{
            ComputerName         = 'Google-Pixelbook'
            LocalAdminCredential = $localCred
            Wifi                 = @(
                @{ Ssid = 'PublicWifi' }
                @{ Ssid = 'PrivateWifi'; SecurityKey = 'WhiteCollar' }
            )
            Force                = $true
        }

        Mock Get-Location { @{ Path = 'home\ppkgs' } }

        Mock Get-CustomizationsArg {
            @{
                ComputerName         = $ComputerName
                LocalAdminCredential = $localCred
                DomainName           = 'Musashino'
                DomainJoinCredential = $domainCred
                Application          = @(
                    @{
                        Name            = 'explorer.exe'
                        Path            = 'explorer.exe'
                        Command         = 'cmd /c "explorer.exe"'
                        ContinueInstall = $true
                        RestartRequired = $false
                        RestartExitCode = 3010
                        SuccessExitCode = 0
                    }
                    @{
                        Name            = 'test.exe'
                        Path            = 'test.exe'
                        Command         = 'cmd /c "test.exe"'
                        ContinueInstall = $true
                        RestartRequired = $true
                        RestartExitCode = 3010
                        SuccessExitCode = 0
                    }
                )
            }
        }

        Mock New-CustomizationsXmlDocument {
            $doc = [xml]::new()
            $doc.LoadXml('<root>text1</root>')
            $doc
        }

        Mock New-Guid { [guid]::new($fakeGuid) }

        Mock Set-XmlContent { } -ParameterFilter { $Path -eq $fakeXmlPath }

        Mock Confirm-PackagePath { 'C:\test\name.ppkg' }

        Mock Test-Path { $true } -ParameterFilter { $Path -eq 'C:\test\name.ppkg' }

        Mock Get-IcdArg { ('arg1', 'arg2') } -ParameterFilter {
            $IcdPath -eq 'C:\adk\icd.exe'
            $XmlPath -eq $fakeXmlPath -and
            $PackagePath -eq 'C:\test\name.ppkg'
        }

        Mock Start-Process {
            Resolve-Path -Path $FilePath
        } -ParameterFilter {
            $FilePath -like "*icd.exe" -and
            $ArgumentList -ccontains 'arg1' -and
            $ArgumentList -ccontains 'arg2' -and
            $WindowStyle -eq 'Hidden' -and
            $Wait -eq $true -and
            $RedirectStandardError -eq (Join-Path $env:TEMP -ChildPath 'ProvisioningTools-ICD.log')
        }

        Mock Remove-Item { } -ParameterFilter { $Path -eq $fakeXmlPath }

        Context 'Parameter validation' {
            $invalidComputerNameCases = @(
                @{
                    ComputerName         = 'xDre#@6asfd'
                    LocalAdminCredential = $localCred
                },
                @{
                    ComputerName         = 'AEREFAHdaHAREHAREHArehAREherhAREjhAETJeatJAETJaetjatJaregAERharEGareGaerHGaerHearHearHareg'
                    LocalAdminCredential = $localCred
                },
                @{
                    ComputerName         = '234-adf rew'
                    LocalAdminCredential = $localCred
                }
            )
            It 'raises an error with invalid computer name "<ComputerName>"' -TestCases $invalidComputerNameCases {
                param( $ComputerName, $LocalAdminCredential )
                {
                    $packageParams = @{
                        ComputerName         = $ComputerName
                        LocalAdminCredential = $LocalAdminCredential
                        Path                 = 'C:\test'
                    }
                    New-ProvisioningPackage @packageParams
                } | Should -Throw 'Supply a name composed of'

            }

            It 'Path parameter is not mandatory' {
                $getAttrParams = @{
                    Command   = 'New-ProvisioningPackage'
                    Parameter = 'Path'
                }
                (Get-ParameterAttribute @getAttrParams).Mandatory | Should -BeFalse
            }

            It 'ComputerName parameter is mandatory' {
                $getAttrParams = @{
                    Command   = 'New-ProvisioningPackage'
                    Parameter = 'ComputerName'
                }
                (Get-ParameterAttribute @getAttrParams).Mandatory | Should -BeTrue
            }

            It 'ComputerName accepts pipeline input by value' {
                $getAttrParams = @{
                    Command = 'New-ProvisioningPackage'
                    Parameter = 'ComputerName'
                }
                (Get-ParameterAttribute @getAttrParams).ValueFromPipeline | Should -BeTrue
            }

            It 'LocalAdminCredential parameter is mandatory' {
                $getAttrParams = @{
                    Command   = 'New-ProvisioningPackage'
                    Parameter = 'LocalAdminCredential'
                }
                (Get-ParameterAttribute @getAttrParams).Mandatory | Should -BeTrue
            }

            It 'DomainName parameter is mandatory' {
                $getAttrParams = @{
                    Command   = 'New-ProvisioningPackage'
                    Parameter = 'DomainName'
                }
                (Get-ParameterAttribute @getAttrParams).Mandatory | Should -BeTrue
            }

            It 'DomainName parameter is a member of the Domain parameter set' {
                $getAttrParams = @{
                    Command   = 'New-ProvisioningPackage'
                    Parameter = 'DomainName'
                }
                (Get-ParameterAttribute @getAttrParams).ParameterSetName | Should -BeExactly 'Domain'
            }

            It 'DomainJoinCredential parameter is mandatory' {
                $getAttrParams = @{
                    Command   = 'New-ProvisioningPackage'
                    Parameter = 'DomainJoinCredential'
                }
                (Get-ParameterAttribute @getAttrParams).Mandatory | Should -BeTrue
            }

            It 'DomainJoinCredential parameter is a member of the Domain parameter set' {
                $getAttrParams = @{
                    Command   = 'New-ProvisioningPackage'
                    Parameter = 'DomainJoinCredential'
                }
                (Get-ParameterAttribute @getAttrParams).ParameterSetName | Should -BeExactly 'Domain'
            }

            It 'Application parameter is not mandatory' {
                $getAttrParams = @{
                    Command   = 'New-ProvisioningPackage'
                    Parameter = 'Application'
                }
                (Get-ParameterAttribute @getAttrParams).Mandatory | Should -BeFalse
            }

            It 'Wifi parameter is not mandatory' {
                $getAttrParams = @{
                    Command   = 'New-ProvisioningPackage'
                    Parameter = 'Wifi'
                }
                (Get-ParameterAttribute @getAttrParams).Mandatory | Should -BeFalse
            }

            It 'Force is not mandatory' {
                $getAttrParams = @{
                    Command   = 'New-ProvisioningPackage'
                    Parameter = 'Force'
                }
                (Get-ParameterAttribute @getAttrParams).Mandatory | Should -BeFalse
            }
        }

        Context 'Package generation (pipeline input)' {
            'Bob-Dylan', 'thinkblue' | New-ProvisioningPackage @params1

            It 'processes its parameters for XML generation' {
                Assert-MockCalled Get-CustomizationsArg -Times 2 -Exactly -ExclusiveFilter {
                    $ComputerName -in ('Bob-Dylan', 'thinkblue') -and
                    $LocalAdminCredential -eq $localCred -and
                    $DomainName -eq 'Musashino' -and
                    $DomainJoinCredential -eq $domainCred -and
                    $Application[0] -eq 'explorer.exe' -and
                    $Application[1].Path -eq 'test.exe' -and
                    $Application[1].RestartRequired -eq $true
                }
            }

            It 'generates XML documents' {
                Assert-MockCalled New-CustomizationsXmlDocument -Times 2 -Exactly -ExclusiveFilter {
                    $ComputerName -in ('Bob-Dylan', 'thinkblue') -and
                    $LocalAdminCredential -eq $localCred -and
                    $DomainName -eq 'Musashino' -and
                    $DomainJoinCredential -eq $domainCred -and
                    $Application[0].Name -eq 'explorer.exe' -and
                    $Application[0].Path -eq 'explorer.exe' -and
                    $Application[0].Command -eq 'cmd /c "explorer.exe"' -and
                    $Application[0].ContinueInstall -eq $true -and
                    $Application[0].RestartRequired -eq $false -and
                    $Application[0].RestartExitCode -eq 3010 -and
                    $Application[0].SuccessExitCode -eq 0 -and
                    $Application[1].Name -eq 'test.exe' -and
                    $Application[1].Path -eq 'test.exe' -and
                    $Application[1].Command -eq 'cmd /c "test.exe"' -and
                    $Application[1].ContinueInstall -eq $true -and
                    $Application[1].RestartRequired -eq $true -and
                    $Application[1].RestartExitCode -eq 3010 -and
                    $Application[1].SuccessExitCode -eq 0
                }
            }

            It 'generates a name for the XML documents' {
                Assert-MockCalled New-Guid -Times 2 -Exactly
            }

            It 'saves the XML documents to the temp folder' {
                Assert-MockCalled Set-XmlContent -Times 2 -Exactly
            }

            It 'gets the output package paths' {
                Assert-MockCalled Confirm-PackagePath -Times 2 -Exactly -ExclusiveFilter {
                    $Path -eq 'C:\test' -and
                    $Force -eq $false
                }
            }

            It 'gets the ICD.exe argument list' {
                Assert-MockCalled Get-IcdArg -Times 2 -Exactly -ExclusiveFilter { $Overwrite -eq $false }
            }

            It 'executes ICD.exe to build the provisioning packages' {
                Assert-MockCalled Start-Process -Times 2 -Exactly
            }

            It 'deletes the customizations XML file' {
                Assert-MockCalled Remove-Item -Times 2 -Exactly
            }
        }

        Mock Get-CustomizationsArg {
            @{
                ComputerName         = 'Google-Pixelbook'
                LocalAdminCredential = $localCred
                Wifi                 = @(
                    @{ Ssid = 'PublicWifi'; SecurityType = 'Open' }
                    @{ Ssid = 'PrivateWifi'; SecurityType = 'WPA2-Personal'; SecurityKey = 'WhiteCollar' }
                )
            }
        }

        Mock Test-Path { $false } -ParameterFilter { $Path -eq 'C:\test\name.ppkg' }

        Context 'Package generation (-Force)' {
            It "raises an error when the output package can't be found" {
                { New-ProvisioningPackage @params2 } | Should -Throw "Couldn't find the output package."
            }

            It 'processes its parameters for XML generation' {
                Assert-MockCalled Get-CustomizationsArg -Exactly -ExclusiveFilter {
                    $ComputerName -eq 'Google-Pixelbook' -and
                    $LocalAdminCredential -eq $localCred -and
                    $Wifi[0].Ssid -eq 'PublicWifi' -and
                    $Wifi[1].Ssid -eq 'PrivateWifi' -and
                    $Wifi[1].SecurityKey -eq 'WhiteCollar'
                }
            }

            It 'generates XML documents' {
                Assert-MockCalled New-CustomizationsXmlDocument -Exactly -ExclusiveFilter {
                    $ComputerName -eq 'Google-Pixelbook' -and
                    $LocalAdminCredential -eq $localCred
                    $Wifi[0].Ssid -eq 'PublicWifi' -and
                    $Wifi[0].SecurityType -eq 'Open' -and
                    $Wifi[1].Ssid -eq 'PrivateWifi' -and
                    $Wifi[1].SecurityType -eq 'WPA2-Personal' -and
                    $Wifi[1].SecurityKey -eq 'WhiteCollar'
                }
            }

            It 'generates a name for the XML documents' {
                Assert-MockCalled New-Guid -Times 1 -Exactly
            }

            It 'saves the XML documents to the temp folder' {
                Assert-MockCalled Set-XmlContent -Times 1 -Exactly
            }

            It 'gets the output package paths' {
                Assert-MockCalled Confirm-PackagePath -Times 1 -Exactly -ExclusiveFilter {
                    $Path -eq 'home\ppkgs' -and
                    $Force -eq $true
                }
            }

            It 'gets the ICD.exe argument list' {
                Assert-MockCalled Get-IcdArg -Times 1 -Exactly -ExclusiveFilter { $Overwrite -eq $true }
            }

            It 'executes ICD.exe to build the provisioning packages' {
                Assert-MockCalled Start-Process -Times 1 -Exactly
            }

            It 'deletes the customizations XML file' {
                Assert-MockCalled Remove-Item -Times 1 -Exactly
            }
        }
    }
}