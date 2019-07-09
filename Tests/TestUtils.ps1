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
    
function Test-ApplicationProperty {
    param ($InApp, $OutApp, $PropertyName)
    # Given one or more input Applications and output Applications,
    # verify that the specified property on the output is as expected.
    for ($i = 0; $i -lt @($InApp).Count; $i++) {
        $currentApp = @($InApp)[$i]
        $inValue = $currentApp[$PropertyName]
        $outValue = @($OutApp)[$i][$PropertyName]
        if ($PropertyName -eq 'Path' -and $currentApp -is [string]) {
            # Special case for when the input Application is a path string instead of a hashtable
            $inValue = $currentApp
        }
        if ($null -eq $inValue) {
            # Set some defaults when no input was provided
            # (except for Path, which is required)
            if ($currentApp -is [string]) {
                $path = $currentApp
            }
            else {
                $path = $currentApp.Path
            }
            if (!$path) { $path = $path.Path }
            switch ($PropertyName) {
                'Name' {
                    $inValue = Split-Path -Leaf -Path $path
                }
                'Command' {
                    $inValue = 'cmd /c "{0}"' -f (Split-Path -Leaf -Path $path)
                }
                'ContinueInstall' { $inValue = $true }
                'RestartRequired' { $inValue = $false }
                'RestartExitCode' { $inValue = 3010 }
                'SuccessExitCode' { $inValue = 0 }
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