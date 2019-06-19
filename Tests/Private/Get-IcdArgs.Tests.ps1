InModuleScope $ProjectName {
    Describe 'Get-IcdArgs' {
        $params = @(
            @{
                IcdPath     = 'C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Imaging and Configuration Designer\x86\ICD.exe'
                XmlPath     = (Join-Path -Path $env:TEMP -ChildPath 'customizations.xml')
                PackagePath = 'C:\packages\PC05.ppkg'
                Overwrite   = $false
            }
            @{
                IcdPath     = 'C:\adk\icd.exe'
                XmlPath     = 'C:\stuff\customizations.xml'
                PackagePath = 'C:\morestuff\server.ppkg'
                Overwrite   = $true
            }
            @{
                IcdPath     = 'C:\icd.exe'
                XmlPath     = 'C:\Users\Bob\doc.xml'
                PackagePath = 'C:\Users\Bob\mainframe.ppkg'
                Overwrite   = $true
            }
        )
        $testCases = $params | ForEach-Object -Begin { $i = 0 } -Process {
            $storeFilePath = (Join-Path -Path (Split-Path -Parent -Path $_.IcdPath) -ChildPath 'Microsoft-Desktop-Provisioning.dat')
            $overwriteSymbol = if ($_.Overwrite) { '+' } else { '-' }
            @{
                Expected = @{
                    BuildFlag     = '/Build-ProvisioningPackage'
                    XmlPath       = '/CustomizationXml:"{0}"' -f $_.XmlPath
                    PackagePath   = '/PackagePath:"{0}"' -f $_.PackagePath
                    StoreFilePath = '/StoreFile:"{0}"' -f $storeFilePath
                    Overwrite     = "$($overwriteSymbol)Overwrite"
                }
                Result = Get-IcdArgs @_
                CaseIndex = ++$i
            }
        }

        It 'returns the correct number of parameters' -TestCases $testCases {
            param($Expected, $Result)
            $Result | Should -HaveCount 5
        }

        It 'case <CaseIndex>: returns /Build-ProvisioningPackage argument' -TestCases $testCases {
            param($Expected, $Result)
            $Result | Should -Contain $Expected.BuildFlag
        }

        It 'case <CaseIndex>: returns expected /CustomizationXML argument' -TestCases $testCases {
            param($Expected, $Result)
            $Result | Should -Contain $Expected.XmlPath
        }

        It 'case <CaseIndex>: returns expected /PackagePath argument' -TestCases $testCases {
            param($Expected, $Result)
            $Result | Should -Contain $Expected.PackagePath
        }

        It 'case <CaseIndex>: returns expected /StoreFile argument' -TestCases $testCases {
            param($Expected, $Result)
            $Result | Should -Contain $Expected.StoreFilePath
        }

        It 'case <CaseIndex>: returns expected Overwrite argument' -TestCases $testCases {
            param($Expected, $Result)
            $Result | Should -Contain $Expected.Overwrite
        }
    }
}