function Get-IcdArg {
    [CmdletBinding()]
    [OutputType([Array])]
    param (
        [string] $IcdPath,
        [string] $XmlPath,
        [string] $PackagePath,
        [bool] $Overwrite
    )

    $storePath = Join-Path -Path (Split-Path -Parent -Path $IcdPath) -ChildPath 'Microsoft-Desktop-Provisioning.dat'
    $overwriteSymbol = if ($Overwrite) { '+' } else { '-' }
    @(
        '/Build-ProvisioningPackage'
        "/CustomizationXML:`"$XmlPath`""
        "/PackagePath:`"$PackagePath`""
        "/StoreFile:`"$storePath`""
        "$($overwriteSymbol)Overwrite"
    )
}