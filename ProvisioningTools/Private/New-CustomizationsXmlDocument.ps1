function New-CustomizationsXmlDocument {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions",
        "", Justification = "Does not change state")]
    param (
        [string] $ComputerName,
        [pscredential] $LocalAdminCredential,
        [string] $DomainName,
        [pscredential] $DomainJoinCredential,
        [hashtable[]] $Application,
        [hashtable[]] $Wifi
    )

    $packageConfigNamespace = 'urn:schemas-Microsoft-com:Windows-ICD-Package-Config.v1.0'
    $wpns = 'urn:schemas-microsoft-com:windows-provisioning'


    [xml]$doc = New-Object System.Xml.XmlDocument
    $doc.AppendChild($doc.CreateXmlDeclaration('1.0', 'utf-8', $null)) | Out-Null
    $root = $doc.CreateElement('WindowsCustomizations')

    # ----------------
    # PackageConfig
    # ----------------
    $packageConfig = $doc.CreateElement('PackageConfig', $packageConfigNamespace)

    $id = $doc.CreateElement('ID', $packageConfigNamespace)
    $id.AppendChild($doc.CreateTextNode((New-Guid).ToString('B'))) | Out-Null
    $packageConfig.AppendChild($id) | Out-Null

    $name = $doc.CreateElement('Name', $packageConfigNamespace)
    $name.InnerText = "$ComputerName"
    $packageConfig.AppendChild($name) | Out-Null

    $version = $doc.CreateElement('Version', $packageConfigNamespace)
    $version.InnerText = '1.0'
    $packageConfig.AppendChild($version) | Out-Null

    $owner = $doc.CreateElement('OwnerType', $packageConfigNamespace)
    $owner.InnerText = 'ITAdmin'
    $packageConfig.AppendChild($owner) | Out-Null

    $rank = $doc.CreateElement('Rank', $packageConfigNamespace)
    $packageConfig.AppendChild($rank) | Out-Null
    $rank.InnerText = '0'

    $root.AppendChild($packageConfig) | Out-Null

    # ----------------
    # Settings
    # ----------------
    $settings = $doc.CreateElement('Settings', $wpns)

    $customizations = $doc.CreateElement('Customizations', $wpns)
    $common = $doc.CreateElement('Common', $wpns)
    $accounts = $doc.CreateElement('Accounts', $wpns)
    $computerAccount = $doc.CreateElement('ComputerAccount', $wpns)

    $computerNameNode = $doc.CreateElement('ComputerName', $wpns)
    $computerNameNode.AppendChild($doc.CreateTextNode($ComputerName)) | Out-Null
    $computerAccount.AppendChild($computerNameNode) | Out-Null

    if ($DomainName) {
        $domainNameNode = $doc.CreateElement('DomainName', $wpns)
        $domainNameNode.AppendChild($doc.CreateTextNode($DomainName)) | Out-Null
        $computerAccount.AppendChild($domainNameNode) | Out-Null

        $domainUserName = $doc.CreateElement('Account', $wpns)
        $domainUserName.AppendChild($doc.CreateTextNode($DomainJoinCredential.UserName)) | Out-Null
        $computerAccount.AppendChild($domainUserName) | Out-Null

        $domainPassword = $doc.CreateElement('Password', $wpns)
        $domainPassword.AppendChild($doc.CreateTextNode($DomainJoinCredential.GetNetworkCredential().Password)) | Out-Null
        $computerAccount.AppendChild($domainPassword) | Out-Null
    }
    $accounts.AppendChild($computerAccount) | Out-Null

    $users = $doc.CreateElement('Users', $wpns)
    $user = $doc.CreateElement('User', $wpns)
    $user.SetAttribute('UserName', $LocalAdminCredential.UserName)

    $userPassword = $doc.CreateElement('Password', $wpns)
    $userPassword.AppendChild($doc.CreateTextNode($LocalAdminCredential.GetNetworkCredential().Password)) | Out-Null
    $user.AppendChild($userPassword) | Out-Null

    $userGroup = $doc.CreateElement('UserGroup', $wpns)
    $userGroup.InnerText = 'Administrators'
    $user.AppendChild($userGroup) | Out-Null

    $users.AppendChild($user) | Out-Null
    $accounts.AppendChild($users) | Out-Null
    $common.AppendChild($accounts) | Out-Null

    $oobe = Add-XmlChildElement -Parent $common -Name 'OOBE' -PassThru
    $desktop = Add-XmlChildElement -Parent $oobe -Name 'Desktop' -PassThru
    Add-XmlChildElement -Parent $desktop -Name 'HideOobe' -InnerText 'True'

    $policies = $doc.CreateElement('Policies', $wpns)
    $applicationManagement = $doc.CreateElement('ApplicationManagement', $wpns)
    $allowAllTrustedApps = $doc.CreateElement('AllowAllTrustedApps', $wpns)
    $allowAllTrustedApps.InnerText = 'Yes'
    $applicationManagement.AppendChild($allowAllTrustedApps) | Out-Null
    $policies.AppendChild($applicationManagement) | Out-Null
    $common.AppendChild($policies) | Out-Null

    if ($Application) {
        $provisioningCommands = $doc.CreateElement('ProvisioningCommands', $wpns)
        $primaryContext = $doc.CreateElement('PrimaryContext', $wpns)
        $command = $doc.CreateElement('Command', $wpns)
        $Application | ForEach-Object -Process {
            $commandConfig = $doc.CreateElement('CommandConfig', $wpns)
            $commandConfig.SetAttribute('Name', $_.Name)

            $commandFile = $doc.CreateElement('CommandFile', $wpns)
            $commandFile.InnerText = $_.Path
            $commandConfig.AppendChild($commandFile) | Out-Null

            $commandLine = $doc.CreateElement('CommandLine', $wpns)
            $commandLine.InnerText = $_.Command
            $commandConfig.AppendChild($commandLine) | Out-Null

            $continueInstall = $doc.CreateElement('ContinueInstall', $wpns)
            $continueInstall.InnerText = $_.ContinueInstall
            $commandConfig.AppendChild($continueInstall) | Out-Null

            $restartRequired = $doc.CreateElement('RestartRequired', $wpns)
            $restartRequired.InnerText = $_.RestartRequired
            $commandConfig.AppendChild($restartRequired) | Out-Null

            Add-XmlChildElement -Parent $commandConfig -Name 'ReturnCodeRestart' -InnerText $_.RestartExitCode
            Add-XmlChildElement $commandConfig 'ReturnCodeSuccess' $_.SuccessExitCode

            $command.AppendChild($commandConfig) | Out-Null
        }

        $primaryContext.AppendChild($command) | Out-Null
        $provisioningCommands.AppendChild($primaryContext) | Out-Null
        $common.AppendChild($provisioningCommands) | Out-Null
    }

    $customizations.AppendChild($common) | Out-Null

    if ($Wifi) {
        $targets = Add-XmlChildElement -Parent $customizations -Name 'Targets' -PassThru
        $target = Add-XmlChildElement -Parent $targets -Name 'Target' -PassThru
        $target.SetAttribute('Id', 'laptop')

        $targetState = Add-XmlChildElement -Parent $target -Name 'TargetState' -PassThru
        $condition = Add-XmlChildElement -Parent $targetState -Name 'Condition' -PassThru
        $condition.SetAttribute('Name', 'PowerPlatformRole')
        $condition.SetAttribute('Value', '2')

        $variant = Add-XmlChildElement -Parent $customizations -Name 'Variant' -PassThru
        $targetRefs = Add-XmlChildElement -Parent $variant -Name 'TargetRefs' -PassThru
        $targetRef = Add-XmlChildElement -Parent $targetRefs -Name 'TargetRef' -PassThru
        $targetRef.SetAttribute('Id', 'laptop')

        $variantSettings = Add-XmlChildElement -Parent $variant -Name 'Settings' -PassThru
        $connectivityProfiles = Add-XmlChildElement -Parent $variantSettings -Name 'ConnectivityProfiles' -PassThru
        $wlan = Add-XmlChildElement -Parent $connectivityProfiles -Name 'WLAN' -PassThru
        $wlanSetting = Add-XmlChildElement -Parent $wlan -Name 'WLANSetting' -PassThru

        $Wifi | ForEach-Object -Process {
            $wlanConfig = Add-XmlChildElement -Parent $wlanSetting -Name 'WLANConfig' -PassThru
            $wlanConfig.SetAttribute('SSID', $_.Ssid)

            $wlanXmlSettings = Add-XmlChildElement -Parent $wlanConfig -Name 'WLANXmlSettings' -PassThru
            Add-XmlChildElement -Parent $wlanXmlSettings -Name 'SecurityType' -InnerText $_.SecurityType
            if ($_.SecurityKey) {
                Add-XmlChildElement -Parent $wlanXmlSettings -Name 'SecurityKey' -InnerText $_.SecurityKey
            }
            Add-XmlChildElement -Parent $wlanXmlSettings -Name 'AutoConnect' -InnerText $_.AutoConnect
        }
    }
    $settings.AppendChild($customizations) | Out-Null
    $root.AppendChild($settings) | Out-Null
    $doc.AppendChild($root) | Out-Null
    $doc
}