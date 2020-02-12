function New-CustomizationsXmlDocument {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions",
        "", Justification = "Does not change state")]
    param (
        [string] $ComputerName,
        [pscredential] $LocalAdminCredential,
        [string] $DomainName,
        [pscredential] $DomainJoinCredential,
        [hashtable[]] $Application,
        [hashtable[]] $Wifi,
        [string] $KioskXml
    )

    $packageConfigNamespace = 'urn:schemas-Microsoft-com:Windows-ICD-Package-Config.v1.0'
    $settingsNamespace = 'urn:schemas-microsoft-com:windows-provisioning'


    [xml]$doc = New-Object System.Xml.XmlDocument
    $doc.AppendChild($doc.CreateXmlDeclaration('1.0', 'utf-8', $null)) | Out-Null
    $root = Add-XmlChildElement -Parent $doc -Name 'WindowsCustomizations' -PassThru

    # ----------------
    # PackageConfig
    # ----------------
    $packageConfig = Add-XmlChildElement -Parent $root -Name 'PackageConfig' -NamespaceUri $packageConfigNamespace -PassThru
    Add-XmlChildElement -Parent $packageConfig -Name 'ID' -InnerText (New-Guid).ToString('B')
    Add-XmlChildElement -Parent $packageConfig -Name 'Name' -InnerText $ComputerName
    Add-XmlChildElement -Parent $packageConfig -Name 'Version' -InnerText '1.0'
    Add-XmlChildElement -Parent $packageConfig -Name 'OwnerType' -InnerText 'ITAdmin'
    Add-XmlChildElement -Parent $packageConfig -Name 'Rank' -InnerText '0'

    # ----------------
    # Settings
    # ----------------
    $settings = Add-XmlChildElement -Parent $root -Name 'Settings' -NamespaceUri $settingsNamespace -PassThru
    $customizations = Add-XmlChildElement -Parent $settings -Name 'Customizations' -PassThru
    $common = Add-XmlChildElement -Parent $customizations -Name 'Common' -PassThru

    $accounts = Add-XmlChildElement -Parent $common -Name 'Accounts' -PassThru
    $computerAccount = Add-XmlChildElement -Parent $accounts -Name 'ComputerAccount' -PassThru
    Add-XmlChildElement -Parent $computerAccount -Name 'ComputerName' -InnerText $ComputerName
    if ($DomainName) {
        Add-XmlChildElement -Parent $computerAccount -Name 'DomainName' -InnerText $DomainName
        Add-XmlChildElement -Parent $computerAccount -Name 'Account' -InnerText $DomainJoinCredential.UserName
        Add-XmlChildElement -Parent $computerAccount -Name 'Password' -InnerText $DomainJoinCredential.GetNetworkCredential().Password
    }
    $users = Add-XmlChildElement -Parent $accounts -Name 'Users' -PassThru
    $user = Add-XmlChildElement -Parent $users -Name 'User' -PassThru
    $user.SetAttribute('UserName', $LocalAdminCredential.UserName)
    Add-XmlChildElement -Parent $user -Name 'Password' -InnerText $LocalAdminCredential.GetNetworkCredential().Password
    Add-XmlChildElement -Parent $user -Name 'UserGroup' -InnerText 'Administrators'

    $assignedAccess = Add-XmlChildElement -Parent $common -Name 'AssignedAccess' -PassThru
    Add-XmlChildElement -Parent $assignedAccess -Name 'MultiAppAssignedAccessSettings' -InnerText $KioskXml

    $oobe = Add-XmlChildElement -Parent $common -Name 'OOBE' -PassThru
    $desktop = Add-XmlChildElement -Parent $oobe -Name 'Desktop' -PassThru
    Add-XmlChildElement -Parent $desktop -Name 'HideOobe' -InnerText 'True'

    $policies = Add-XmlChildElement -Parent $common -Name 'Policies' -PassThru
    $applicationManagement = Add-XmlChildElement -Parent $policies -Name 'ApplicationManagement' -PassThru
    Add-XmlChildElement -Parent $applicationManagement -Name 'AllowAllTrustedApps' -InnerText 'Yes'

    if ($Application) {
        $provisioningCommands = Add-XmlChildElement -Parent $common -Name 'ProvisioningCommands' -PassThru
        $primaryContext = Add-XmlChildElement -Parent $provisioningCommands -Name 'PrimaryContext' -PassThru
        $command = Add-XmlChildElement -Parent $primaryContext -Name 'Command' -PassThru
        $Application | ForEach-Object -Process {
            $commandConfig = Add-XmlChildElement -Parent $command -Name 'CommandConfig' -PassThru
            $commandConfig.SetAttribute('Name', $_.Name)
            Add-XmlChildElement -Parent $commandConfig -Name 'CommandFile' -InnerText $_.BatchPath
            Add-XmlChildElement -Parent $commandConfig -Name 'CommandLine' -InnerText $_.BatchCmd
            $dependencyPackages = Add-XmlChildElement -Parent $commandConfig -Name 'DependencyPackages' -PassThru
            $_.Dependencies | ForEach-Object {
                $dependency = Add-XmlChildElement -Parent $dependencyPackages -Name 'Dependency' -InnerText $_.Path -PassThru
                $dependency.SetAttribute('Name', $_.Name)
            }
            Add-XmlChildElement -Parent $commandConfig -Name 'ContinueInstall' -InnerText $_.ContinueInstall
            Add-XmlChildElement -Parent $commandConfig -Name 'RestartRequired' -InnerText $_.RestartRequired
            Add-XmlChildElement -Parent $commandConfig -Name 'ReturnCodeRestart' -InnerText $_.RestartExitCode
            Add-XmlChildElement -Parent $commandConfig -Name 'ReturnCodeSuccess' -InnerText $_.SuccessExitCode
        }
    }

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

    $doc
}