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
                    Name               = 'test.exe'
                    BatchPath          = 'C:\temp\tmp552C.bat'
                    BatchCmd           = 'cmd /c "tmp552C.bat"'
                    Command            = 'cmd /c "test.exe"'
                    Dependencies       = @{
                        Name = 'test.exe'
                        Path = 'C:\temp\test.exe'
                    }
                    ContinueInstall    = $true
                    RestartRequired    = $false
                    RestartExitCode    = '3010'
                    SuccessExitCode    = 0
                }
                Wifi                 = @(
                    @{ Ssid = 'H@ckMe'; SecurityType = 'Open'; AutoConnect = $false }
                    @{ Ssid = 'PineTree'; SecurityType = 'WPA2-Personal'; SecurityKey = 'Maple#Syrup114' }
                )
                KioskXml = 'C:\path\to\kiosk.xml'
            }
            @{
                ComputerName         = 'pi'
                DomainName           = 'CONTOSO'
                DomainJoinCredential = Get-CredentialFromPlainText -UserName 'gladmin' -Password 'the cAkE is a LIE'
                LocalAdminCredential = Get-CredentialFromPlainText -UserName 'Aoi' -Password 'Don-don-donuts'
                Application          = @(
                    @{
                        BatchPath          = 'C:\Users\kumiko\AppData\Local\Temp\tmp4A21.bat'
                        BatchCmd           = 'cmd /c "tmp4A21.bat"'
                        Name               = 'MyApp'
                        Command            = 'app.exe /silent'
                        Dependencies       = @(
                            @{
                                Name = 'app.exe'
                                Path = 'C:\Users\kumiko\app.exe'
                            },
                            @{
                                Name = 'app.dll'
                                Path = 'C:\Users\kumiko\app.dll'
                            }
                        )
                        ContinueInstall    = $false
                        RestartRequired    = $true
                        RestartExitCode    = 123
                        SuccessExitCode    = -1
                    },
                    @{
                        BatchPath          = 'C:\Windows\tmpF229.bat'
                        BatchCmd           = 'cmd /c "tmpF229.bat"'
                        Name               = 'Notepad'
                        Command            = 'setup.exe --quiet'
                        Dependencies       = @{
                            Name = 'setup.exe'
                            Path = 'C:\temp\setup.exe'
                        }
                        ContinueInstall    = $true
                        RestartRequired    = $true
                        RestartExitCode    = 405
                        SuccessExitCode    = 0
                    }
                )
                KioskXml = "C:\temp\kiosk-settings.xml"
            }
            @{
                ComputerName         = 'DESKTOP-MIYAMORI'
                LocalAdminCredential = Get-CredentialFromPlainText -UserName 'Katyusha' -Password 'Russ1anHack3r!#'
            }
            @{
                ComputerName         = 'Kaguya-sama'
                LocalAdminCredential = Get-CredentialFromPlainText -UserName 'chika' -Password 'BOOM-BOOM-YO!'
                Application          = @{
                    BatchPath          = 'C:\isabella\destroy_computer.bat'
                    BatchCmd           = 'cmd /c "destroy_computer.bat'
                    Name               = 'The Promised Neverland'
                    Command            = 'destroy_computer.exe --mode "DESTROOOOOY_ yoUr CoMPutEr sPikE SPiEgeL"'
                    Dependencies       = @(
                        @{
                            Name = 'comp.dll'
                            Path = 'C:\temp\comp.dll'
                        },
                        @{
                            Name = 'destroy_computer.exe'
                            Path = 'C:\isabella\destroy_computer.exe'
                        }
                    )
                    ContinueInstall    = $false
                    RestartRequired    = $false
                    RestartExitCode    = 3010
                    SuccessExitCode    = 0
                }
                Wifi                 = @{ Ssid = 'Musashino'; SecurityType = 'WPA2-Personal'; SecurityKey = 'ThirdAerialGirlsSquad' }
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
                    CommandPkgsMsg     = 'inserts expected command dependency packages'
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
                    CommandPkgsMsg     = 'command dependency packages are absent (no applications were provided)'
                    ContinueInstallMsg = '"continue install" flags are absent (no applications were provided)'
                    RestartRequiredMsg = '"restart required" flags are absent (no applications were provided)'
                    RestartExitCodeMsg = 'restart exit codes are absent (no applications were provided)'
                    SuccessExitCodeMsg = 'success exit codes are absent (no applications were provided)'
                }
            }

            if ($_.Wifi) {
                $case += @{
                    TargetIdMsg             = 'inserts a target with ID of "laptop"'
                    TargetConditionNameMsg  = 'inserts the PowerPlatformRole target condition'
                    TargetConditionValueMsg = 'sets the PowerPlatformRole target condition value'
                    TargetRefIdMsg          = 'inserts a TargetRef with an ID of "laptop"'
                    WifiSsidMsg             = 'inserts expected Wi-Fi SSIDs'
                    WifiSecurityTypeMsg     = 'inserts expected Wi-Fi security types'
                    WifiSecurityKeyMsg      = 'inserts expected Wi-Fi security keys'
                    WifiAutoConnectMsg      = 'inserts expected auto-connect setting'
                }
            }
            else {
                $case += @{
                    TargetIdMsg             = '"laptop" target is absent (no Wi-Fi settings were provided)'
                    TargetConditionNameMsg  = 'PowerPlatformRole target condition is absent (no Wi-Fi settings were provided)'
                    TargetConditionValueMsg = 'PowerPlatformRole target condition value is absent (no Wi-Fi settings were provided)'
                    TargetRefIdMsg          = '"laptop" TargetRef is absent (no Wi-Fi settings were provided)'
                    WifiSsidMsg             = 'Wi-Fi SSIDs are absent (no Wi-Fi settings were provided)'
                    WifiSecurityTypeMsg     = 'Wi-Fi security types are absent (no Wi-Fi settings were provided)'
                    WifiSecurityKeyMsg      = 'Wi-Fi security keys are absent (no Wi-Fi settings were provided)'
                    WifiAutoConnectMsg      = 'Wi-Fi auto-connect setting is absent (no Wi-Fi settings were provided)'
                }
            }

            if ($_.KioskXml) {
                $case.KioskXmlMsg = 'inserts expected kiosk XML path'
            }
            else {
                $case.KioskXmlMsg = 'kiosk XML path is absent (no XML was provided)'
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
                param($Doc, $Params)
                $node = Get-NodesFromXPathQuery -XmlDocument $Doc -Query '//wp:ComputerName/text()'
                $node.Value | Should -Be $Params.ComputerName
            }

            It 'case <CaseIndex>: <DomainNameMsg>' -TestCases $testCases {
                param($Doc, $Params)
                $node = Get-NodesFromXPathQuery -XmlDocument $Doc -Query '//wp:DomainName/text()'
                if ($Params.DomainName) {
                    $node.Value | Should -Be $Params.DomainName
                }
                else {
                    $node.Value | Should -BeNullOrEmpty
                }
            }

            It 'case <CaseIndex>: <DomainUserNameMsg>' -TestCases $testCases {
                param($Doc, $Params)
                $node = Get-NodesFromXPathQuery -XmlDocument $Doc -Query '//wp:Account/text()'
                if ($Params.DomainName) {
                    $node.Value | Should -Be $Params.DomainJoinCredential.UserName
                }
                else {
                    $node.Value | Should -BeNullOrEmpty
                }
            }

            It 'case <CaseIndex>: <DomainPasswordMsg>' -TestCases $testCases {
                param($Doc, $Params)
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
                param($Doc, $Params)
                $node = Get-NodesFromXPathQuery -XmlDocument $Doc -Query '//wp:User/@UserName'
                $node.Value | Should -Be $Params.LocalAdminCredential.UserName
            }

            It 'case <CaseIndex>: inserts expected local password' -TestCases $testCases {
                param($Doc, $Params)
                $node = Get-NodesFromXPathQuery -XmlDocument $Doc -Query '//wp:User/wp:Password/text()'
                $node.Value | Should -Be $Params.LocalAdminCredential.GetNetworkCredential().Password
            }

            It 'case <CaseIndex>: inserted local account is a member of Administrators' -TestCases $testCases {
                param($Doc, $Params)
                $node = Get-NodesFromXPathQuery -XmlDocument $Doc -Query '//wp:UserGroup/text()'
                $node.Value | Should -Be 'Administrators'
            }
        }

        Context 'XML document values: provisioning settings' {
            It 'case <CaseIndex>: hide OOBE is enabled' -TestCases $testCases {
                param($Doc, $Params)
                $node = Get-NodesFromXPathQuery -XmlDocument $Doc -Query '//wp:HideOobe/text()'
                $node.Value | Should -Be 'True'
            }

            It 'case <CaseIndex>: allow all trusted apps is enabled' -TestCases $testCases {
                param($Doc, $Params)
                $node = Get-NodesFromXPathQuery -XmlDocument $Doc -Query '//wp:AllowAllTrustedApps/text()'
                $node.Value | Should -Be 'Yes'
            }

            It 'case <CaseIndex>: <KioskXmlMsg>' -TestCases $testCases {
                param($Doc, $Params)
                $node = Get-NodesFromXPathQuery -XmlDocument $Doc -Query '//wp:AssignedAccess/wp:MultiAppAssignedAccessSettings/text()'
                $node.Value | Should -Be $Params.KioskXml
            }
        }

        Context 'XML document values: application settings' {
            It 'case <CaseIndex>: inserted application count matches expected application count' -TestCases $testCases {
                param($Doc, $Params)
                $target = if ($Params.Application) { @($Params.Application).Count } else { 0 }
                $nodes = Get-NodesFromXPathQuery -XmlDocument $Doc -Query '//wp:PrimaryContext/wp:Command/wp:CommandConfig'
                $nodes | Should -HaveCount $target
            }

            It 'case <CaseIndex>: <CommandNameMsg>' -TestCases $testCases {
                param($Doc, $Params)
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
                param($Doc, $Params)
                for ($i = 0; $i -lt @($Params.Application).Count; $i++) {
                    $target = @($Params.Application)[$i].BatchPath
                    $queryParams = @{
                        XmlDocument = $Doc
                        Query       = "//wp:PrimaryContext/wp:Command/wp:CommandConfig[$($i + 1)]/wp:CommandFile/text()"
                    }
                    $node = Get-NodesFromXPathQuery @queryParams
                    $node.Value | Should -Be $target
                }
            }

            It 'case <CaseIndex>: <CommandLineMsg>' -TestCases $testCases {
                param($Doc, $Params)
                for ($i = 0; $i -lt @($Params.Application).Count; $i++) {
                    $target = @($Params.Application)[$i].BatchCmd
                    $queryParams = @{
                        XmlDocument = $Doc
                        Query       = "//wp:PrimaryContext/wp:Command/wp:CommandConfig[$($i + 1)]/wp:CommandLine/text()"
                    }
                    $node = Get-NodesFromXPathQuery @queryParams
                    $node.Value | Should -Be $target
                }
            }

            It 'case <CaseIndex>: <CommandPkgsMsg>' -TestCases $testCases {
                param($Doc, $Params)
                for ($i = 0; $i -lt @($Params.Application).Count; $i++) {
                    $target = @(@($Params.Application)[$i].Dependencies)
                    for ($j = 0; $j -lt $target.Count; $j++) {
                        $queryParams = @{
                            XmlDocument = $Doc
                            Query = "//wp:PrimaryContext/wp:Command/wp:CommandConfig[$($i + 1)]/wp:DependencyPackages/wp:Dependency[$($j + 1)]"
                        }
                        $node = Get-NodesFromXPathQuery @queryParams
                        if ($node) {
                            $node.Attributes['Name'].Value | Should -Be $target[$j].Name
                            $node.InnerText | Should -Be $target[$j].Path
                        }
                        else {
                            $target[$j] | Should -BeNullOrEmpty
                        }
                    }
                }
            }

            It 'case <CaseIndex>: <ContinueInstallMsg>' -TestCases $testCases {
                param($Doc, $Params)
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
                param($Doc, $Params)
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
                param($Doc, $Params)
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
                param($Doc, $Params)
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

        Context 'XML document values: Wi-Fi settings' {
            It 'case <CaseIndex>: <TargetIdMsg>' -TestCases $testCases {
                param($Doc, $Params)
                if ($Params.Wifi) {
                    $target = 'laptop'
                }
                else {
                    $target = $null
                }
                $queryParams = @{
                    XmlDocument = $Doc
                    Query       = '//wp:Customizations/wp:Targets/wp:Target/@Id'
                }
                $node = Get-NodesFromXPathQuery @queryParams
                $node.Value | Should -Be $target
            }

            It 'case <CaseIndex>: <TargetConditionNameMsg>' -TestCases $testCases {
                param($Doc, $Params)
                if ($Params.Wifi) {
                    $target = 'PowerPlatformRole'
                }
                else {
                    $target = $null
                }
                $queryParams = @{
                    XmlDocument = $Doc
                    Query       = '//wp:Customizations/wp:Targets/wp:Target/wp:TargetState/wp:Condition/@Name'
                }
                $node = Get-NodesFromXPathQuery @queryParams
                $node.Value | Should -Be $target
            }

            It 'case <CaseIndex>: <TargetConditionValueMsg>' -TestCases $testCases {
                param($Doc, $Params)
                if ($Params.Wifi) {
                    $target = '2'
                }
                else {
                    $target = $null
                }
                $queryParams = @{
                    XmlDocument = $Doc
                    Query       = '//wp:Customizations/wp:Targets/wp:Target/wp:TargetState/wp:Condition/@Value'
                }
                $node = Get-NodesFromXPathQuery @queryParams
                $node.Value | Should -Be $target
            }

            It 'case <CaseIndex>: <TargetRefIdMsg>' -TestCases $testCases {
                param($Doc, $Params)
                if ($Params.Wifi) {
                    $target = 'laptop'
                }
                else {
                    $target = $null
                }
                $queryParams = @{
                    XmlDocument = $Doc
                    Query       = '//wp:Customizations/wp:Variant/wp:TargetRefs/wp:TargetRef/@Id'
                }
                $node = Get-NodesFromXPathQuery @queryParams
                $node.Value | Should -Be $target
            }

            It 'case <CaseIndex>: <WifiSsidMsg>' -TestCases $testCases {
                param($Doc, $Params)
                $wifiArray = @($Params.Wifi)
                for ($i = 0; $i -lt $wifiArray.Count; $i++) {
                    $target = $wifiArray[$i].Ssid
                    $queryParams = @{
                        XmlDocument = $Doc
                        Query       = "//wp:WLAN/wp:WLANSetting/wp:WLANConfig[$($i + 1)]/@SSID"
                    }
                    $node = Get-NodesFromXPathQuery @queryParams
                    $node.Value | Should -Be $target
                }
            }

            It 'case <CaseIndex>: <WifiSecurityTypeMsg>' -TestCases $testCases {
                param($Doc, $Params)
                $wifiArray = @($Params.Wifi)
                for ($i = 0; $i -lt $wifiArray.Count; $i++) {
                    $target = $wifiArray[$i].SecurityType
                    $queryParams = @{
                        XmlDocument = $Doc
                        Query       = "//wp:WLAN/wp:WLANSetting/wp:WLANConfig[$($i + 1)]/wp:WLANXmlSettings/wp:SecurityType/text()"
                    }
                    $node = Get-NodesFromXPathQuery @queryParams
                    $node.Value | Should -Be $target
                }
            }

            It 'case <CaseIndex>: <WifiSecurityKeyMsg>' -TestCases $testCases {
                param($Doc, $Params)
                $wifiArray = @($Params.Wifi)
                for ($i = 0; $i -lt $wifiArray.Count; $i++) {
                    $target = $wifiArray[$i].SecurityKey
                    $queryParams = @{
                        XmlDocument = $Doc
                        Query       = "//wp:WLAN/wp:WLANSetting/wp:WLANConfig[$($i + 1)]/wp:WLANXmlSettings/wp:SecurityKey/text()"
                    }
                    $node = Get-NodesFromXPathQuery @queryParams
                    $node.Value | Should -Be $target
                }
            }

            It 'case <CaseIndex>: <WifiAutoConnectMsg>' -TestCases $testCases {
                param($Doc, $Params)
                $wifiArray = @($Params.Wifi)
                for ($i = 0; $i -lt $wifiArray.Count; $i++) {
                    switch ($wifiArray[$i].AutoConnect) {
                        $true { $target = 'True' }
                        $false { $target = 'False' }
                        Default { $target = $null }
                    }
                    $queryParams = @{
                        XmlDocument = $Doc
                        Query       = "//wp:WLAN/wp:WLANSetting/wp:WLANConfig[$($i + 1)]/wp:WLANXmlSettings/wp:AutoConnect/text()"
                    }
                    $node = Get-NodesFromXPathQuery @queryParams
                    $node.Value | Should -Be $target
                }
            }
        }
    }
}