function Set-XmlContent {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType($null)]
    param (
        [xml] $XmlDocument,
        [string] $Path
    )

    if ($PSCmdlet.ShouldProcess("Path: $Path", "Save XML Document")) {
        $XmlDocument.Save($Path)
    }
}