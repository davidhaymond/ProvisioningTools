function Get-CustomizationsArg {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [string] $ComputerName,
        [pscredential] $LocalAdminCredential,
        [string] $DomainName,
        [pscredential] $DomainJoinCredential,
        [System.Object[]] $Application,
        [hashtable[]] $Wifi
    )

    $args = @{ }
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -notin ('Application', 'Wifi')) {
            $args[$key] = $PSBoundParameters[$key]
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
            if (-not (Test-Path -Path $app.Path -PathType Leaf)) {
                Write-Error ('The application "{0}" cannot be found.' -f $app.Path)
            }
            else {
                $app.Path = Resolve-Path -Path $app.Path
            }
            if (!$app.Name) {
                $app.Name = Split-Path -LeafBase -Path $app.Path
            }
            if (!$app.Command) {
                $app.Command = 'cmd /c "{0}"' -f (Split-Path -Leaf -Path $app.Path)
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

            $app
        }
    }
    $args
}