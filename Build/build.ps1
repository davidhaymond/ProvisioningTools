param(
    $Task = 'default',
    $TestName
)

if ($env:APPVEYOR -and $PSVersionTable.Edition -eq 'Core') {
    '======= PowerShell Core ======`n'
}
elseif ($env:APPVEYOR -and $PSVersionTable.Edition -eq 'Desktop') {
    '===== Windows PowerShell =====`n'
}

$dependencies = @(
    @{ModuleName='psake'; ModuleVersion='4.8.0'},
    @{ModuleName='PSScriptAnalyzer'; ModuleVersion='1.18.0'},
    @{ModuleName='Pester'; ModuleVersion='4.8.1'}
)
$dependenciesInstallMsg = 'Installing build dependencies'
$dependencies | ForEach-Object -Process {
    $name = $_.ModuleName
    $version = $_.ModuleVersion
    try {
        $moduleInfo = Get-Module -Name $name
        if (!$moduleInfo -or ($moduleInfo -and $moduleInfo.Version -lt $version)) {
            Remove-Module -Name $name -Force -ErrorAction SilentlyContinue
            Import-Module -Name $name -MinimumVersion $version -Force -ErrorAction Stop
        }
    }
    catch {
        if ($dependenciesInstallMsg) {
            $dependenciesInstallMsg
            # Only print the dependencies install message once
            $dependenciesInstallMsg = $null
        }
        "`tInstalling $($name)"
        Install-Module -Name $name -MinimumVersion $version -Scope CurrentUser -Force -SkipPublisherCheck
        Import-Module -Name $name -MinimumVersion $version -Force
    }
}
$psakeParams = @{
    taskList = $Task
}
if ($TestName) {
    $psakeParams.parameters = @{ TestName = $TestName }
}
Invoke-psake $PSScriptRoot\psakefile.ps1 @psakeParams
exit ([int](!$psake.build_success))