# Get public and private function definition files.
$public = @(Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue)
$private = @(Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue)

# Dot source the files
Foreach ($import in @($public + $private)) {
    Try {
        . $import.FullName
    }
    Catch {
        Write-Error "Failed to import function $($import.FullName): $_"
    }
}