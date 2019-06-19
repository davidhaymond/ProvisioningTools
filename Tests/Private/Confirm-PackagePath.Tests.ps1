InModuleScope $ProjectName {
    Describe 'Confirm-PackagePath' {
        Context 'File exists at the specified path' {
            Mock Test-Path { $true } -Verifiable -ParameterFilter {
                $Path -eq '\home\user\ppkgs' -and
                $PathType -eq 'Leaf'
            }

            Mock Test-Path { $true } -Verifiable -ParameterFilter {
                $Path -eq 'c:\Users\alphonse\packages' -and
                $PathType -eq 'Leaf'
            }

            Mock New-Item { } -ParameterFilter {
                $Path -eq 'c:\Users\alphonse\packages' -and
                $ItemType -eq 'Directory' -and
                $Force -eq $true
            }

            $result = Confirm-PackagePath -ComputerName 'Pixelbook' -Path 'c:\Users\alphonse\packages' -Force

            It "returns the combined path and computer name if -Force is specified" {
                $result | Should -BeExactly 'c:\Users\alphonse\packages\Pixelbook.ppkg'
            }


            It 'overwrites the file with a new directory if -Force is specified' {
                Assert-MockCalled New-Item -Exactly
            }

            It "raises an error if -Force isn't specified" {
                { Confirm-PackagePath -ComputerName 'Pixelbook' -Path '\home\user\ppkgs' } |
                    Should -Throw '"\home\user\ppkgs"'
            }

            It "checks for the path's existence" {
                Assert-VerifiableMock
            }
        }

        Context "Directory exists at the specified path and package path also exists" {
            Mock Test-Path { $true }

            Mock Test-Path { $false } -ParameterFilter {
                $Path -eq 'c:\packages\' -and
                $PathType -eq 'Leaf'
            }

            Mock Test-Path { $true } -ParameterFilter {
                $Path -eq 'c:\packages\linux.ppkg'
            }

            $result = Confirm-PackagePath -ComputerName 'linux' -Path 'c:\packages\' -Force

            It "checks for the existence of the folder path" {
                Assert-MockCalled Test-Path -ParameterFilter { $Path -eq 'c:\packages\'}
            }

            It 'returns the combined path and computer name if -Force is specified' {
                $result | Should -BeExactly 'c:\packages\linux.ppkg'
            }

            It "raises an error if -Force isn't specified" {
                { Confirm-PackagePath -ComputerName 'linux' -Path 'c:\packages\' } |
                    Should -Throw '"c:\packages\linux.ppkg"'
            }

            It 'checks for the existence of the package path' {
                Assert-MockCalled Test-Path -ParameterFilter { $Path -eq 'c:\packages\linux.ppkg' }
            }
        }

        Context 'Neither directory or file exists at specified path' {
            Mock Test-Path { $false } -Verifiable -ParameterFilter {
                $Path -eq 'stuff' -and
                $PathType -eq 'Leaf'
            }

            $result = Confirm-PackagePath -ComputerName 'watson' -Path 'stuff'

            It "checks for the path's existence" {
                Assert-VerifiableMock
            }

            It 'returns the combined path and computer name' {
                $result | Should -BeExactly 'stuff\watson.ppkg'
            }
        }
    }
}