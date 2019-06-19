function Copy-Hashtable {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        $InputObject
    )
    process {
        if ($InputObject -is [hashtable]) {
            $clone = @{ }
            foreach ($key in $InputObject.Keys) {
                $clone[$key] = Copy-Hashtable -InputObject $InputObject[$key]
            }
            return $clone
        }
        else {
            return $InputObject
        }
    }
}