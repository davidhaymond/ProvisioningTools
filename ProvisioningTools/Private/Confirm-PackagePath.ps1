function Confirm-PackagePath {
    [OutputType($null, [string])]
    param (
        [string] $ComputerName,
        [string] $Path,
        [switch] $Force
    )

    if (Test-Path -Path $Path -PathType Leaf) {
        if ($Force) {
            New-Item -ItemType Directory -Path $Path -Force
        }
        else {
            throw "A file already exists at the path `"$Path`". (Use the -Force parameter to overwrite files.)"
        }
    }
    $ppkgPath = Join-Path -Path $Path -ChildPath "$ComputerName.ppkg"
    if (!$Force -and (Test-Path -Path $ppkgPath)) {
        Write-Error "An item already exists at the path `"$ppkgPath`". (Use the -Force parameter to overwrite files.)"
    }
    else {
        $ppkgPath
    }
}