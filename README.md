[![Build status](https://ci.appveyor.com/api/projects/status/shs6dj4nu1p89ipt/branch/master?svg=true)](https://ci.appveyor.com/project/davidhaymond/provisioningtools/branch/master)

# ProvisioningTools
A PowerShell module for creating Windows 10 provisioning packages.

## Installation
```powershell
Install-Module ProvisioningTools
```

*Note that `ProvisioningTools` requires **PowerShell Core 6.1 or later**.
Linux and macOS are not currently supported.*

## Usage
The simplest way to use this tool is demonstrated here:

```powershell
New-ProvisioningPackage -ComputerName PC01, PC02
```

This command creates two provisioning packages, one for the device named PC01
and one for PC02, and saves them to your hard drive as the files `PC01.ppkg` and
`PC02.ppkg`.

In this example, `New-ProvisioningPackage` will prompt for a local admin
credential since the required `-LocalAdminCredential` parameter was omitted.
Both of the packages will create a local administrator account with the specified
credentials.

In addition to this basic functionality, packages can join devices to a domain,
install applications, and set up Wi-Fi profiles. For details on how to use
this tool, read the help:

```powershell
help New-ProvisioningPackage
```

## Downloading the Source Code
Use Git to clone the repository:

```
git clone https://github.com/davidhaymond/ProvisioningTools.git
```

## Building the Repository
Building the module and running the test suite is simple. After cloning
the repository, run the following commands:

```powershell
cd ProvisioningTools
.\Build\build.ps1
```

The build script will automatically install the following
build dependencies if needed:

 - [psake](https://github.com/psake/psake)
 - [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer)
 - [Pester](https://github.com/pester/Pester)

The build pipeline is powered by psake. By default, `build.ps1`
will execute the Build task. Several other tasks are available
and can be specified with the `-Task` parameter:

 - **Analyze**: Check the code for common problems.
 - **Test**:    Run the test suite and code coverage report.
 - **Build**:   Update the module manifest's exported functions to match the source code.
                Also runs **Analyze** and **Test**.

For example, the following command executes the test suite:

```powershell
.\Build\build.ps1 -Task Test
```
