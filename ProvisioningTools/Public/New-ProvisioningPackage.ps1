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
        Packages can optionally join the computer to a domain and install applications.

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
        Lists zero or more applications to install during provisioning.
        This parameter accepts an array of values, each of which should be either
        a string or a hashtable.

        If a string is used, it should point to the path of the installer. Note
        that the installer will be run without any command-line arguments.

        If a hashtable is used, it should contain one or more of the following keys:

            - Path (required): Specifies the path to the application installer.
            - Name:            Specifies the name of the application. Defaults to
                               the installer filename.
            - Command:         Specifies the command executed during provisioning.
                               Defaults to 'cmd /c "<setup.exe>"', where <setup.exe>
                               is replaced with the name of the installer. Include this
                               key when you need to pass command-line arguments to the
                               executable (e.g. to cause an installer to run silently).
            - ContinueInstall: A Boolean that indicates whether subsequent installations
                               should continue if the current install fails. Defaults
                               to $true.
            - RestartRequired: A Boolean that indicates whether or not to force a restart
                               after installing this application (and before proceeding
                               with subsequent installations). Defaults to $false.
            - RestartExitCode: Specifies the exit code returned by the installer that
                               indicates a restart is needed to complete installation.
                               Defaults to 3010.
            - SuccessExitCode: Specifies the exit code returned by the installer that
                               indicates the installation was successful. Defaults to 0.

    .PARAMETER Path
        Specifies the output directory to save the provisioning packages to.

    .PARAMETER Force
        Forces New-ProvisioningItem to overwrite existing files.

    .EXAMPLE
        New-ProvisioningPackage -ComputerName PC01, PC02 -LocalAdminCredential Admin

        Creates two provisioning packages (PC01.ppkg, PC02.ppkg), one for each computer
        specified in the ComputerName parameter. The packages will create a local
        administrator account named 'Admin' on each computer.

    .EXAMPLE
        Get-Content computer-names.txt | New-ProvisioningPackage -LocalAdminCredential User
        -Application .\Office\setup.exe

        Gets a list of computer names from computer-names.txt and pipes them
        to New-ProvisioningPackage, which generates a new package for each computer name
        in computer-names.txt. Each package will provision its respective device with
        a local administrator account named 'User', and execute the '.\Office\setup.exe'
        installer during the provisioning process.

    .EXAMPLE
        $apps = @(
            'setup.exe',
            @{
                Path            = 'C:\install.exe'
                Command         = 'cmd /c "install.exe" /quiet'
                RestartRequired = $true
            }
        )
        New-ProvisioningPackage -ComputerName Bob-Laptop -LocalAdminCredential admin
        -DomainName CONTOSO -DomainJoinCredential CONTOSO\Admin -Application $apps

        Creates a provisioning package for computer name 'Bob-Laptop'. In addition to
        naming the computer, the provisioning package will join the device to the
        CONTOSO domain using the CONTOSO\Admin account and create a local admininistrator
        account named 'admin'. Two applications are specified for installation:
        setup.exe from the current directory, and C:\install.exe. The latter application
        will be run with the '/quiet' argument, and the device will restart after installation.

    .NOTES
        For more information about provisioning packages, visit
        https://docs.microsoft.com/en-us/windows/configuration/provisioning-packages/provisioning-packages
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

        [string]
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
            }
            $customizationsArgs = Get-CustomizationsArg @params
            $doc = New-CustomizationsXmlDocument @customizationsArgs
            $ppkgPath = Confirm-PackagePath -ComputerName $currentComputerName -Path $Path -Force:$Force

            if ($ppkgPath -and $PSCmdlet.ShouldProcess("Paths: $ppkgPath", "Build Provisioning Package")) {

                # Generate filename and save the XML doc to disk
                $guid = (New-Guid).ToString('D')
                $xmlPath = Join-Path -Path $env:TEMP -ChildPath "$guid.xml"
                Set-XmlContent -XmlDocument $doc -Path $xmlPath -Confirm:$false

                try {
                    # Run ICD.exe to generate the provisioning package
                    $icdArgs = Get-IcdArg -IcdPath $icdPath -XmlPath $xmlPath -PackagePath $ppkgPath -Overwrite $Force
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
                    $catPath = Join-Path -Path $Path -ChildPath "$($currentComputerName).cat"
                    Remove-Item -Path $catPath -ErrorAction SilentlyContinue -Confirm:$false
                    Remove-Item -Path $xmlPath -ErrorAction SilentlyContinue -Confirm:$false
                }

                if (Test-Path $ppkgPath) {
                    Remove-Item $icdLogPath -ErrorAction SilentlyContinue
                }
                else {
                    Write-Error "Couldn't find the output package. Please see $icdLogPath for details."
                }
            }
        }
    }
}