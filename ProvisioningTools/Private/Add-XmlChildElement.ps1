using namespace System.Xml

function Add-XmlChildElement {
    [CmdletBinding()]
    [OutputType($null, [XmlNode])]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0
        )]
        [XmlNode] $Parent,

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
    if ($Parent -is [XmlDocument]) {
        $document = $Parent
    }
    else {
        $document = $Parent.OwnerDocument
    }
    $child = $document.CreateElement($Name, $NamespaceUri)
    if ($InnerText) {
        $child.InnerText = $InnerText
    }
    $Parent.AppendChild($child) | Out-Null
    if ($PassThru) {
        $child
    }
}