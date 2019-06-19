InModuleScope $ProjectName {
    . "$PSScriptRoot\..\TestUtils.ps1"
    Describe 'New-CustomizationsXmlDocument' {
        $xmlDocParamsList = @(
            @{
                ComputerName         = '001DC'
                DomainName           = 'GHIBLI'
                DomainJoinCredential = Get-CredentialFromPlainText -UserName 'DomainJoiner' -Password 'Join1234'
                LocalAdminCredential = Get-CredentialFromPlainText -UserName 'Admin' -Password 'ReallySecurePassword'
                Application          = @{
                    Name            = 'test.exe'
                    Path            = 'C:\temp\test.exe'
                    Command         = 'cmd /c "test.exe"'
                    ContinueInstall = $true
                    RestartRequired = $false
                    RestartExitCode = '3010'
                    SuccessExitCode = 0
                }
            }
            @{
                ComputerName         = 'pi'
                DomainName           = 'CONTOSO'
                DomainJoinCredential = Get-CredentialFromPlainText -UserName 'gladmin' -Password 'the cAkE is a LIE'
                LocalAdminCredential = Get-CredentialFromPlainText -UserName 'Aoi' -Password 'Don-don-donuts'
                Application          = @(
                    @{
                        Path            = 'C:\Users\kumiko\icd.exe'
                        Name            = 'icd.exe'
                        Command         = 'cmd /c "icd.exe"'
                        ContinueInstall = $false
                        RestartRequired = $true
                        RestartExitCode = 123
                        SuccessExitCode = -1
                    },
                    @{
                        Path            = 'C:\Windows\notepad.exe'
                        Name            = 'Notepad'
                        Command         = 'notepad.exe'
                        ContinueInstall = $true
                        RestartRequired = $true
                        RestartExitCode = 405
                        SuccessExitCode = 0
                    }
                )
            }
            @{
                ComputerName         = 'DESKTOP-MIYAMORI'
                LocalAdminCredential = Get-CredentialFromPlainText -UserName 'Katyusha' -Password 'Russ1anHack3r!#'
            }
            @{
                ComputerName         = 'Kaguya-sama'
                LocalAdminCredential = Get-CredentialFromPlainText -UserName 'chika' -Password 'BOOM-BOOM-YO!'
                Application          = @{
                    Path            = 'C:\isabella\destroy_computer.exe'
                    Name            = 'DESTROOOOOY_ yoUr CoMPutEr sPikE SPiEgeL'
                    Command         = 'cmd /c "destroy_computer.exe"'
                    ContinueInstall = $false
                    RestartRequired = $false
                    RestartExitCode = 3010
                    SuccessExitCode = 0
                }
            }
        )

        $i = 0
        $testCases = $xmlDocParamsList | ForEach-Object -Process {
            $case = @{
                CaseIndex = ++$i
                Doc       = (New-CustomizationsXmlDocument @_)
                Params    = $_
            }

            if ($_.DomainName) {
                $case += @{
                    DomainNameMsg     = 'inserts expected domain name'
                    DomainUserNameMsg = 'inserts expected domain username'
                    DomainPasswordMsg = 'inserts expected domain password'
                }
            }
            else {
                $case += @{
                    DomainNameMsg     = 'domain name is absent (workgroup)'
                    DomainUserNameMsg = 'domain username is absent (workgroup)'
                    DomainPasswordMsg = 'domain password is absent (workgroup)'
                }
            }

            if ($_.Application) {
                $case += @{
                    CommandNameMsg     = 'inserts expected command names'
                    CommandFileMsg     = 'inserts expected command files'
                    CommandLineMsg     = 'inserts expected command lines'
                    ContinueInstallMsg = 'inserts expected "continue install" flags'
                    RestartRequiredMsg = 'inserts expected "restart required" flags'
                    RestartExitCodeMsg = 'inserts expected restart exit codes'
                    SuccessExitCodeMsg = 'inserts expected success exit codes'
                }
            }
            else {
                $case += @{
                    CommandNameMsg     = 'command names are absent (no applications were provided)'
                    CommandFileMsg     = 'command files are absent (no applications were provided)'
                    CommandLineMsg     = 'command lines are absent (no applications were provided)'
                    ContinueInstallMsg = '"continue install" flags are absent (no applications were provided)'
                    RestartRequiredMsg = '"restart required" flags are absent (no applications were provided)'
                    RestartExitCodeMsg = 'restart exit codes are absent (no applications were provided)'
                    SuccessExitCodeMsg = 'success exit codes are absent (no applications were provided)'
                }
            }
            $case
        }

        Context 'Well-formed and validated XML' {
            It 'case <CaseIndex>: produces schema-validated XML' -TestCases $testCases {
                param($CaseIndex, $Doc)
                $validXmlParams = @{
                    XmlDocument = $Doc
                    Schema      = @(
                        @{
                            Path      = "$PSScriptRoot\..\XmlSchemas\customizations.xsd"
                            Namespace = $null
                        }
                        @{
                            Path      = "$PSScriptRoot\..\XmlSchemas\Windows-ICD-Package-Config.v1.0.xsd"
                            Namespace = 'urn:schemas-Microsoft-com:Windows-ICD-Package-Config.v1.0'
                        }
                        @{
                            Path      = "$PSScriptRoot\..\XmlSchemas\windows-provisioning.xsd"
                            Namespace = 'urn:schemas-microsoft-com:windows-provisioning'
                        }
                    )
                }
                Confirm-ValidXml @validXmlParams
            }
        }

        Context 'XML document values: computer name and domain info' {
            It 'case <CaseIndex>: inserts expected computer name' -TestCases $testCases {
                param($CaseIndex, $Doc, $Params)
                $node = Get-NodesFromXPathQuery -XmlDocument $Doc -Query '//wp:ComputerName/text()'
                $node.Value | Should -Be $Params.ComputerName
            }

            It 'case <CaseIndex>: <DomainNameMsg>' -TestCases $testCases {
                param($CaseIndex, $Doc, $Params, $DomainNameMsg)
                $node = Get-NodesFromXPathQuery -XmlDocument $Doc -Query '//wp:DomainName/text()'
                if ($Params.DomainName) {
                    $node.Value | Should -Be $Params.DomainName
                }
                else {
                    $node.Value | Should -BeNullOrEmpty
                }
            }

            It 'case <CaseIndex>: <DomainUserNameMsg>' -TestCases $testCases {
                param($CaseIndex, $Doc, $Params, $DomainUserNameMsg)
                $node = Get-NodesFromXPathQuery -XmlDocument $Doc -Query '//wp:Account/text()'
                if ($Params.DomainName) {
                    $node.Value | Should -Be $Params.DomainJoinCredential.UserName
                }
                else {
                    $node.Value | Should -BeNullOrEmpty
                }
            }

            It 'case <CaseIndex>: <DomainPasswordMsg>' -TestCases $testCases {
                param($CaseIndex, $Doc, $Params, $DomainNameMsg)
                $node = Get-NodesFromXPathQuery -XmlDocument $Doc -Query '//wp:ComputerAccount/wp:Password/text()'
                if ($Params.DomainName) {
                    $node.Value | Should -Be $Params.DomainJoinCredential.GetNetworkCredential().Password
                }
                else {
                    $node.Value | Should -BeNullOrEmpty
                }
            }
        }

        Context 'XML document values: local admin account' {
            It 'case <CaseIndex>: inserts expected local username' -TestCases $testCases {
                param($CaseIndex, $Doc, $Params)
                $node = Get-NodesFromXPathQuery -XmlDocument $Doc -Query '//wp:User/@UserName'
                $node.Value | Should -Be $Params.LocalAdminCredential.UserName
            }

            It 'case <CaseIndex>: inserts expected local password' -TestCases $testCases {
                param($CaseIndex, $Doc, $Params)
                $node = Get-NodesFromXPathQuery -XmlDocument $Doc -Query '//wp:User/wp:Password/text()'
                $node.Value | Should -Be $Params.LocalAdminCredential.GetNetworkCredential().Password
            }

            It 'case <CaseIndex>: inserted local account is a member of Administrators' -TestCases $testCases {
                param($CaseIndex, $Doc, $Params)
                $node = Get-NodesFromXPathQuery -XmlDocument $Doc -Query '//wp:UserGroup/text()'
                $node.Value | Should -Be 'Administrators'
            }
        }

        Context 'XML document values: provisioning settings' {
            It 'case <CaseIndex>: hide OOBE is enabled' -TestCases $testCases {
                param($CaseIndex, $Doc, $Params)
                $node = Get-NodesFromXPathQuery -XmlDocument $Doc -Query '//wp:HideOobe/text()'
                $node.Value | Should -Be 'True'
            }

            It 'case <CaseIndex>: allow all trusted apps is enabled' -TestCases $testCases {
                param($CaseIndex, $Doc, $Params)
                $node = Get-NodesFromXPathQuery -XmlDocument $Doc -Query '//wp:AllowAllTrustedApps/text()'
                $node.Value | Should -Be 'Yes'
            }
        }

        Context 'XML document values: application settings' {
            It 'case <CaseIndex>: inserted application count matches expected application count' -TestCases $testCases {
                param($CaseIndex, $Doc, $Params)
                $target = if ($Params.Application) { @($Params.Application).Count } else { 0 }
                $nodes = Get-NodesFromXPathQuery -XmlDocument $Doc -Query '//wp:PrimaryContext/wp:Command/wp:CommandConfig'
                $nodes | Should -HaveCount $target
            }

            It 'case <CaseIndex>: <CommandNameMsg>' -TestCases $testCases {
                param($CaseIndex, $Doc, $Params, $CommandNameMsg)
                for ($i = 0; $i -lt @($Params.Application).Count; $i++) {
                    $target = @($Params.Application)[$i].Name
                    $queryParams = @{
                        XmlDocument = $Doc
                        Query       = "//wp:PrimaryContext/wp:Command/wp:CommandConfig[$($i + 1)]/@Name"
                    }
                    $node = Get-NodesFromXPathQuery @queryParams
                    $node.Value | Should -Be $target
                }
            }

            It 'case <CaseIndex>: <CommandFileMsg>' -TestCases $testCases {
                param($CaseIndex, $Doc, $Params, $CommandFileMsg)
                for ($i = 0; $i -lt @($Params.Application).Count; $i++) {
                    $target = @($Params.Application)[$i].Path
                    $queryParams = @{
                        XmlDocument = $Doc
                        Query       = "//wp:PrimaryContext/wp:Command/wp:CommandConfig[$($i + 1)]/wp:CommandFile/text()"
                    }
                    $node = Get-NodesFromXPathQuery @queryParams
                    $node.Value | Should -Be $target
                }
            }

            It 'case <CaseIndex>: <CommandLineMsg>' -TestCases $testCases {
                param($CaseIndex, $Doc, $Params, $CommandLineMsg)
                for ($i = 0; $i -lt @($Params.Application).Count; $i++) {
                    $target = @($Params.Application)[$i].Command
                    $queryParams = @{
                        XmlDocument = $Doc
                        Query       = "//wp:PrimaryContext/wp:Command/wp:CommandConfig[$($i + 1)]/wp:CommandLine/text()"
                    }
                    $node = Get-NodesFromXPathQuery @queryParams
                    $node.Value | Should -Be $target
                }
            }

            It 'case <CaseIndex>: <ContinueInstallMsg>' -TestCases $testCases {
                param($CaseIndex, $Doc, $Params, $ContinueInstallMsg)
                for ($i = 0; $i -lt @($Params.Application).Count; $i++) {
                    switch (@($Params.Application)[$i].ContinueInstall) {
                        $true { $target = 'True' }
                        $false { $target = 'False' }
                        Default { $target = $null }
                    }
                    $queryParams = @{
                        XmlDocument = $Doc
                        Query       = "//wp:PrimaryContext/wp:Command/wp:CommandConfig[$($i + 1)]/wp:ContinueInstall/text()"
                    }
                    $node = Get-NodesFromXPathQuery @queryParams
                    $node.Value | Should -Be $target
                }
            }

            It 'case <CaseIndex>: <RestartRequiredMsg>' -TestCases $testCases {
                param($CaseIndex, $Doc, $Params, $RestartRequiredMsg)
                for ($i = 0; $i -lt @($Params.Application).Count; $i++) {
                    switch (@($Params.Application)[$i].RestartRequired) {
                        $true { $target = 'True' }
                        $false { $target = 'False' }
                        Default { $target = $null }
                    }
                    $queryParams = @{
                        XmlDocument = $Doc
                        Query       = "//wp:PrimaryContext/wp:Command/wp:CommandConfig[$($i + 1)]/wp:RestartRequired/text()"
                    }
                    $node = Get-NodesFromXPathQuery @queryParams
                    $node.Value | Should -Be $target
                }
            }

            It 'case <CaseIndex>: <RestartExitCodeMsg>' -TestCases $testCases {
                param($CaseIndex, $Doc, $Params, $RestartExitCodeMsg)
                for ($i = 0; $i -lt @($Params.Application).Count; $i++) {
                    $target = @($Params.Application)[$i].RestartExitCode
                    $queryParams = @{
                        XmlDocument = $Doc
                        Query       = "//wp:PrimaryContext/wp:Command/wp:CommandConfig[$($i + 1)]/wp:ReturnCodeRestart/text()"
                    }
                    $node = Get-NodesFromXPathQuery @queryParams
                    $node.Value | Should -Be $target
                }
            }

            It 'case <CaseIndex>: <SuccessExitCodeMsg>' -TestCases $testCases {
                param($CaseIndex, $Doc, $Params, $SuccessExitCodeMsg)
                for ($i = 0; $i -lt @($Params.Application).Count; $i++) {
                    $target = @($Params.Application)[$i].SuccessExitCode
                    $queryParams = @{
                        XmlDocument = $Doc
                        Query       = "//wp:PrimaryContext/wp:Command/wp:CommandConfig[$($i + 1)]/wp:ReturnCodeSuccess/text()"
                    }
                    $node = Get-NodesFromXPathQuery @queryParams
                    $node.Value | Should -Be $target
                }
            }
        }
    }
}