using namespace System.Xml
using namespace System.Xml.Schema

function Confirm-ValidXml {
    param (
        [xml]$XmlDocument,
        [hashtable[]]$Schema
    )

    $settings = New-Object -TypeName XmlReaderSettings
    $settings.ValidationType = [ValidationType]::Schema
    $Schema | ForEach-Object -Process {
        $settings.Schemas.Add($_.Namespace, (Resolve-Path -Path $_.Path)) | Out-Null
    }
    $settings.ValidationFlags = $settings.ValidationFlags -bor [XmlSchemaValidationFlags]::ReportValidationWarnings

    $nodeReader = New-Object -TypeName XmlNodeReader -ArgumentList $XmlDocument
    $reader = [XmlReader]::Create($nodeReader, $settings)
    
    # Throws an exception if the XML document doesn't validate against the schema
    while ($reader.Read()) { }
}

function Get-CredentialFromPlainText {
    
    [Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingPlainTextForPassword', 'Password')]
    param (
        [string] $UserName,
        [string] $Password
    )

    $securePassword = $Password | ConvertTo-SecureString -AsPlainText -Force
    New-Object System.Management.Automation.PSCredential($UserName, $securePassword)    
}

function Get-NodesFromXPathQuery {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            Position = 0
        )]
        [xml]$XmlDocument,

        [Parameter(
            Mandatory = $true,
            Position = 1
        )]
        [string]$Query
    )

    $root = $XmlDocument.DocumentElement
    $nsmgr = New-Object -TypeName System.Xml.XmlNamespaceManager -ArgumentList $XmlDocument.NameTable
    $nsmgr.AddNamespace('wp', 'urn:schemas-microsoft-com:windows-provisioning')
    $root.SelectNodes($Query, $nsmgr)
}

function Test-ObjectProperty {
    param ($InputObject, $OutputObject, $PropertyName)
    # Given one or more input and output objects (Application or Wifi hashtables),
    # verify that the specified property on the output is as expected.
    for ($i = 0; $i -lt @($InputObject).Count; $i++) {
        $currentInputObject = @($InputObject)[$i]
        $currentOutputObject = @($OutputObject)[$i]
        $inValue = $outValue = $null
        if ($null -ne $currentInputObject) {
            $inValue = $currentInputObject[$PropertyName]
        }
        if ($null -ne $currentOutputObject) {
            $outValue = $currentOutputObject[$PropertyName]
        }

        if ($PropertyName -eq 'Path' -and $currentInputObject -is [string]) {
            # Special case for when the input Application is a path string instead of a hashtable
            $inValue = $currentInputObject
        }
        if ($null -eq $inValue) {
            # Set some defaults when no input was provided
            # (except for application path, which is required)
            if ($currentInputObject -is [string]) {
                $path = $currentInputObject
            }
            else {
                $path = $currentInputObject.Path
            }
            if (!$path) { $path = $path.Path }
            switch ($PropertyName) {
                'Name' {
                    $inValue = Split-Path -LeafBase -Path $path
                }
                'Command' {
                    $inValue = 'cmd /c "{0}"' -f (Split-Path -Leaf -Path $path)
                }
                'ContinueInstall' { $inValue = $true }
                'RestartRequired' { $inValue = $false }
                'RestartExitCode' { $inValue = 3010 }
                'SuccessExitCode' { $inValue = 0 }
                'SecurityType' {
                    if ($currentInputObject.SecurityKey) { $inValue = 'WPA2-Personal' }
                    elseif ($currentInputObject) { $inValue = 'Open' }
                }
                Default { }
            }
        }
        $outValue | Should -Be $inValue
    }
}

function Get-ParameterAttribute {
    param (
        [string] $Command,
        [string] $Parameter
    )
    ((Get-Command -Name $Command).Parameters[$Parameter].Attributes |
        Where-Object -FilterScript { $_ -is [Parameter] })
}