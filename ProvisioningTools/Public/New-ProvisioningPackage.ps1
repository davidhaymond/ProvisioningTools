function New-ProvisioningPackage {
    <#
    .SYNOPSIS
        Creates a new Windows 10 desktop provisioning package.

    .DESCRIPTION
        The New-ProvisioningPackage command creates a new Windows 10 provisioning
        package designed to automate setting up a new Windows 10 device
        using a small subset of common settings. Packages can be copied to
        a USB drive and inserted during the Windows Out of Box Experience (OOBE)
        that appears when the device is first powered on. Basic package functionality
        consists of assigning a computer name and local administrator credentials.
        Packages can optionally join the computer to a domain, install applications,
        run scripts, add Wi-Fi profiles, and enable multi-app kiosk mode.

        The -ComputerName parameter accepts multiple computer names,
        and one provisioning package will be created for each computer name.
        You can also pipe a list of computer names to New-ProvisioningPackage.
        Each package will rename the device to the respective computer name
        but the packages are otherwise identical.

    .PARAMETER ComputerName
        Specifies one or more computer names. New-ProvisioningPackage will generate
        one package file for each computer name specified, using the computer name
        as the package file name with the .ppkg extension appended.

    .PARAMETER LocalAdminCredential
        Specifies the credentials of a local administrator account to create.

    .PARAMETER DomainName
        Specifies the name of a domain to join. If omitted, the provisioning package
        will set up the device as a workgroup computer.

    .PARAMETER DomainJoinCredential
        Specifies the credentials of a domain account with permission to join
        computers to a domain.

    .PARAMETER Application
        Specifies a list of applications or scripts to run during provisioning.
        This parameter accepts an array of values, each of which should be either
        a string or a hashtable.

        If a string is used, it should point to the path of the script or executable. Note
        that the file will be invoked without any command-line arguments.

        If a hashtable is used, it should contain one or more of the following keys:

            - Path (required): Specifies one or more scripts or executables.
                               The first file will be executed (unless you specify otherwise
                               using the Command key below). Any additional files will be copied
                               to the same folder and can be referenced by the primary script or
                               executable.
            - Name:            Specifies the name of the application. Defaults to
                               the first Path entry.
            - Command:         Specifies the command executed during provisioning.
                               Defaults to 'cmd /c "<setup.exe>"', where <setup.exe>
                               is replaced with the name of the first entry in the Path key.
                               Include this key when you need to pass command-line arguments to the
                               executable (e.g. to cause an installer to run silently),
                               or if your script isn't a batch file and needs to be run
                               in a shell other than cmd.exe (e.g. powershell.exe).
                               if the current invocation fails. Defaults to $true.
            - ContinueInstall: Indicates whether subsequent installations should continue
                               if the current install fails. Defaults to $true.
            - RestartRequired: Indicates whether or not to force a restart after running
                               this application (and before proceeding with subsequent
                               applications). Defaults to $false.
            - RestartExitCode: Specifies the exit code returned by the installer that
                               indicates a restart is needed to complete installation.
                               Defaults to 3010.
            - SuccessExitCode: Specifies the exit code returned by the installer that
                               indicates the installation was successful. Defaults to 0.

    .PARAMETER Wifi
        Specifies a list of Wi-Fi profiles to configure during provisioning.
        This parameter accepts an array of hashtables, each containing
        one or more of the following keys:

            - Ssid (required): Specifies the Wi-Fi network name or SSID.
            - SecurityKey:     If present, specifies the network security key
                               for a WPA2-Personal Wi-Fi network. Omit this
                               key if the network is open (unsecured).
            - AutoConnect:     Indicates whether the target device should
                               automatically connect to this network when
                               in range. Defaults to $true.

        Note that Wi-Fi profiles will only have an effect on mobile devices
        such as laptops. Desktops will ignore any Wi-Fi profiles.

    .PARAMETER KioskXml
        Specifies the path to an XML file that contains the multi-app kiosk mode
        configuration settings.

        To learn how to create this file, see
        https://docs.microsoft.com/en-us/windows/configuration/lock-down-windows-10-to-specific-apps.

    .PARAMETER Path
        Specifies the output directory to save the provisioning packages to.

    .PARAMETER Force
        Forces New-ProvisioningItem to overwrite existing files.

    .EXAMPLE
        New-ProvisioningPackage -ComputerName PC01, PC02 -LocalAdminCredential Admin

        Creates two provisioning packages (PC01.ppkg, PC02.ppkg), one for each computer
        specified in the ComputerName parameter. The packages will create a local
        administrator account named "Admin" on each computer.

    .EXAMPLE
        Get-Content computer-names.txt | New-ProvisioningPackage -LocalAdminCredential User `
        -Application .\Office\setup.exe -Wifi @{ Ssid = 'Internal'; SecurityKey = 'HouseSpeakerB#' }


        Gets a list of computer names from computer-names.txt and pipes them
        to New-ProvisioningPackage, which generates a new package for each computer name.
        Each package will provision its respective device with a local administrator
        account named "User" and a Wi-Fi profile that connects to the Internal network
        with a security key of "HouseSpeakerB#". The package will also execute the
        ".\Office\setup.exe" installer during the provisioning process.

    .EXAMPLE
        $apps = @(
            'setup.exe',
            @{
                Path            = 'C:\install.exe'
                Command         = 'cmd /c "install.exe" /quiet'
                RestartRequired = $true
            }
        )
        $wifiProfiles = @(
            @{ Ssid = 'ContosoPrivate'; SecurityKey = 'CompanySecrets' }
            @{ Ssid = 'ContosoPublic' }
        )
        New-ProvisioningPackage -ComputerName Bob-Laptop -LocalAdminCredential admin `
        -DomainName CONTOSO -DomainJoinCredential CONTOSO\Admin -Application $apps -Wifi $wifiProfiles


        Creates a provisioning package for computer name "Bob-Laptop". In addition to
        naming the computer, the provisioning package will join the device to the
        CONTOSO domain using the CONTOSO\Admin account and create a local admininistrator
        account named "admin". Two applications are specified for installation:
        setup.exe from the current directory, and C:\install.exe. The latter application
        will be run with the /quiet argument, and the device will restart after installation.
        The package will also configure two Wi-Fi profiles on the target device: the ContosoPrivate
        WPA2-Personal network with a security key of CompanySecrets, and the open ContosoPublic network.

    .EXAMPLE
        New-ProvisioningPackage KIOSK1, KIOSK2 -KioskXml kiosk-settings.xml -Application @{
            Path = ("script.ps1", "data.json")
            Command = "powershell.exe -NoProfile -File script.ps1"
        }

        Creates provisioning packages for two kiosk computers using the settings in kiosk-settings.xml.
        Also executes a PowerShell script, which has access to a supporting datafile (data.json).

    .NOTES
        For more information about provisioning packages, visit
        https://docs.microsoft.com/en-us/windows/configuration/provisioning-packages/provisioning-packages

        For information about multi-app kiosk mode, see
        https://docs.microsoft.com/en-us/windows/configuration/lock-down-windows-10-to-specific-apps
    #>

    [CmdletBinding(
        DefaultParameterSetName = 'Workgroup',
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Low'
    )]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true
        )]
        [ValidatePattern('^[A-Za-z0-9-]{1,63}$',
            ErrorMessage = 'The computer name "{0}" is invalid. ' +
            'Supply a name composed of letters, numbers, and hyphens that is between 1 and 63 characters long.'
        )]
        [string[]]
        $ComputerName,

        [Parameter(
            Mandatory = $true,
            Position = 1
        )]
        [pscredential]
        $LocalAdminCredential,

        [Parameter(
            ParameterSetName = 'Domain',
            Mandatory = $true
        )]
        [string]
        $DomainName,

        [Parameter(
            ParameterSetName = 'Domain',
            Mandatory = $true
        )]
        [pscredential]
        $DomainJoinCredential,

        [object[]]
        $Application,

        [hashtable[]]
        $Wifi,

        [string]
        $KioskXml,

        [string]
        [PSDefaultValue(Help = 'Current directory')]
        $Path = (Get-Location).Path,

        [switch]
        $Force
    )

    begin {
        $icdPath = Join-Path -Path $PSScriptRoot -ChildPath '..\icd\ICD.exe'
    }

    process {
        $ComputerName | ForEach-Object -Process {
            $currentComputerName = $_
            $params = @{
                ComputerName         = $currentComputerName
                LocalAdminCredential = $LocalAdminCredential
                DomainName           = $DomainName
                DomainJoinCredential = $DomainJoinCredential
                Application          = $Application
                Wifi                 = $Wifi
                KioskXml             = $KioskXml
            }
            $customizationsArgs = Get-CustomizationsArg @params
            $doc = New-CustomizationsXmlDocument @customizationsArgs
            $ppkgPath = Confirm-PackagePath -ComputerName $currentComputerName -Path $Path -Force:$Force

            if ($ppkgPath -and $PSCmdlet.ShouldProcess("Paths: $ppkgPath", "Build Provisioning Package")) {

                # Generate filename and save the XML doc to disk
                $xmlFile = New-TemporaryFile
                $base = $xmlFile.BaseName
                $xmlFile = $xmlFile | Rename-Item -NewName "ProvisioningTools-davidhaymond.dev-$base.xml" -PassThru
                Set-XmlContent -XmlDocument $doc -Path $xmlFile.FullName -Confirm:$false

                try {
                    # Run ICD.exe to generate the provisioning package
                    $icdArgs = Get-IcdArg -IcdPath $icdPath -XmlPath $xmlFile.FullName -PackagePath $ppkgPath -Overwrite $Force
                    $icdLogPath = Join-Path $env:TEMP -ChildPath 'ProvisioningTools-ICD.log'
                    $startProcessArgs = @{
                        FilePath              = $icdPath
                        ArgumentList          = $icdArgs
                        WindowStyle           = 'Hidden'
                        Wait                  = $true
                        Confirm               = $false
                        RedirectStandardError = $icdLogPath
                    }
                    Start-Process @startProcessArgs
                }
                finally {
                    # ICD.exe also generates a .cat file in addition to the .ppkg file.
                    # We don't need it, so delete it, along with our customizations XML
                    # and temp batch files.
                    $catPath = Join-Path -Path $Path -ChildPath "$($currentComputerName).cat"
                    Remove-Item -Path $catPath -ErrorAction SilentlyContinue -Confirm:$false -Force
                    Remove-Item -Path "$env:TEMP\ProvisioningTools-davidhaymond.dev*" -ErrorAction SilentlyContinue -Confirm:$false -Force
                }

                if (Test-Path $ppkgPath) {
                    # Package creation was successful, so we don't need the error log
                    Remove-Item $icdLogPath -ErrorAction SilentlyContinue -Confirm:$false -Force
                }
                else {
                    Write-Error "Couldn't find the output package. Please see $icdLogPath for details."
                }
            }
        }
    }
}