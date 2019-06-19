using namespace System.Xml

<#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER Parent
Parameter description

.PARAMETER Name
Parameter description

.PARAMETER InnerText
Parameter description

.PARAMETER NamespaceUri
Parameter description

.PARAMETER PassThru
Parameter description

.EXAMPLE
An example

.NOTES
General notes
#>

function Add-XmlChildElement {
    [CmdletBinding()]
    [OutputType($null, [XmlElement])]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0
        )]
        [XmlElement] $Parent,

        [Parameter(
            Mandatory = $true,
            Position = 1
        )]
        [string] $Name,

        [Parameter(
            Position = 2
        )]
        [string] $InnerText,

        [string] $NamespaceUri,

        [switch] $PassThru
    )
    if (!$NamespaceUri) {
        $NamespaceUri = $Parent.NamespaceURI
    }
    $child = $Parent.OwnerDocument.CreateElement($Name, $NamespaceUri)
    if ($InnerText) {
        $child.InnerText = $InnerText
    }
    $Parent.AppendChild($child) | Out-Null
    if ($PassThru) {
        $child
    }
}