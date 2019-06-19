InModuleScope $ProjectName {
    Describe 'Set-XmlContent' {
        $doc = [xml]::new()
        $xml = '<root>text</root>'
        $doc.LoadXml($xml)
        $path = Join-Path -Path $TestDrive -ChildPath ('doc.xml')
        Set-XmlContent -XmlDocument $doc -Path $path
        It 'saves the XML document to the specified path' {
            Test-Path $path | Should -BeTrue
        }

        It 'writes the correct content to the XML file' {
            Get-Content -Path $path | Should -BeExactly $xml
        }
    }
}