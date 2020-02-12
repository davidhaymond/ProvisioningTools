function Get-CustomizationsArg {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [string] $ComputerName,
        [pscredential] $LocalAdminCredential,
        [string] $DomainName,
        [pscredential] $DomainJoinCredential,
        [System.Object[]] $Application,
        [hashtable[]] $Wifi,
        [string] $KioskXml
    )

    # Save a list of all parameters except Application, Wifi, and KioskXml
    $args = @{ }
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -notin ('Application', 'Wifi', 'KioskXml')) {
            $args[$key] = $PSBoundParameters[$key]
        }
    }

    if ($KioskXml) {
        if (Test-Path $KioskXml) {
            $args.KioskXml = Resolve-Path $KioskXml
        }
        else {
            Write-Error "The kiosk XML file `"$KioskXml`" cannot be found."
        }
    }

    if ($null -ne $Wifi) {
        $args.Wifi = $Wifi | ForEach-Object -Process {
            $wifiArg = $_ | Copy-Hashtable
            if (-not $wifiArg.Ssid) {
                Write-Error 'The Wi-Fi SSID is missing. Make sure that each Wi-Fi hashtable has an Ssid property.'
            }

            if ($wifiArg.SecurityKey) {$wifiArg.SecurityType = 'WPA2-Personal' }
            else { $wifiArg.SecurityType = 'Open' }

            if ($null -eq $wifiArg.AutoConnect) {
                $wifiArg.AutoConnect = $true
            }

            $wifiArg
        }
    }

    if ($null -ne $Application) {
        $args.Application = $Application | ForEach-Object -Process {
            if ($_ -is [string]) {
                $app = @{ Path = $_ }
            }
            elseif ($_ -is [hashtable]) {
                $app = $_ | Copy-Hashtable
            }
            else { Write-Error 'The application is invalid.' }

            if (!$app.Path) {
                Write-Error 'The application path is missing.'
            }

            $firstPath = $app.Path | Select-Object -First 1 | Resolve-Path

            if (!$app.Name) {
                $app.Name = $firstPath | Split-Path -LeafBase
            }
            if (!$app.Command) {
                $app.Command = 'cmd /c "{0}"' -f ($firstPath | Split-Path -Leaf)
            }
            if ($null -eq $app.ContinueInstall) {
                $app.ContinueInstall = $true
            }
            if ($null -eq $app.RestartRequired) {
                $app.RestartRequired = $false
            }
            if ($null -eq $app.RestartExitCode) {
                $app.RestartExitCode = 3010
            }
            if ($null -eq $app.SuccessExitCode) {
                $app.SuccessExitCode = 0
            }

            $app.Dependencies = $app.Path | ForEach-Object {
                if (-not (Test-Path -Path $_ -PathType Leaf)) {
                    Write-Error ('The application "{0}" cannot be found.' -f $_)
                }

                @{
                    Name = $_ | Split-Path -LeafBase
                    Path = $_ | Resolve-Path
                }
            }

            $name = $app.Name
            $batch = New-TemporaryFile
            $base = $batch.BaseName
            $batch = $batch | Rename-Item -NewName "ProvisioningTools-davidhaymond.dev-$base.bat" -PassThru
            Set-Content -Path $batch.FullName -Value @"
set LOGFILE=%SystemDrive%\$name-install.log
echo Executing $($app.Command) >> %LOGFILE%
$($app.Command) >> %LOGFILE%
echo Result: %ERRORLEVEL% >> %LOGFILE%
"@
            $app.BatchPath = $batch.FullName
            $app.BatchCmd = "cmd /c `"$($batch.Name)`""

            $app
        }
    }
    $args
}