InModuleScope $ProjectName {
    . "$PSScriptRoot\..\TestUtils.ps1"
    Describe 'Add-XmlChildElement' {
        Context 'Inheriting parent namespace' {
            $namespace = 'urn:ProvisioningTools-Tests'
            $doc = New-Object -TypeName 'System.Xml.XmlDocument'
            $root = $doc.CreateElement('top', $namespace)
            $root.InnerText = 'The Root'
            $doc.AppendChild($root) | Out-Null

            $text = 'Hello world!'
            $child = Add-XmlChildElement -Parent $root -Name 'child' -InnerText $text -PassThru

            It 'was added to the parent' {
                $child | Should -Be $root.LastChild
            }

            It 'has the same namespace as the parent' {
                $child.NamespaceURI | Should -Be $root.NamespaceURI
            }

            It 'contains the correct inner text' {
                $child.InnerText | Should -Be $text
            }
        }

        Context 'Using custom namespace' {
            $parentNamespace = 'urn:ProvisioningTools-Tests'
            $childNamespace = 'urn:ProvisioningTools-Tests-Child'
            $doc = New-Object -TypeName 'System.Xml.XmlDocument'
            $root = $doc.CreateElement('top', $parentNamespace)
            $root.InnerText = 'The Root'
            $doc.AppendChild($root) | Out-Null

            $text = 'custom namespace!'
            $child = Add-XmlChildElement -Parent $root -Name 'child' -InnerText $text -Namespace $childNamespace -PassThru

            It 'was added to the parent' {
                $child | Should -Be $root.LastChild
            }

            It 'has the correct custom namespace' {
                $child.NamespaceURI | Should -Be $childNamespace
            }

            It 'contains the correct inner text' {
                $child.InnerText | Should -Be $text
            }
        }
    }
}