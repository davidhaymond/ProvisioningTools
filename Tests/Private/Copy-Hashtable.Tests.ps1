InModuleScope $ProjectName {
    Describe 'Copy-Hashtable' {
        $inHash = @{
            Value1 = 'Value1'
            Value2 = 'Value2'
            Ref1   = @{
                Value3 = 'Value3'
                Value4 = 'Value4'
            }
            Ref2   = @{
                Value5 = 'Value5'
                Ref3   = @{
                    Value6 = 'Value6'
                    Value7 = 'Value7'
                }
            }
        }
        # Code duplication intentional to ensure completely separate but identical hashtables
        $outHash = @{
            Value1 = 'Value1'
            Value2 = 'Value2'
            Ref1   = @{
                Value3 = 'Value3'
                Value4 = 'Value4'
            }
            Ref2   = @{
                Value5 = 'Value5'
                Ref3   = @{
                    Value6 = 'Value6'
                    Value7 = 'Value7'
                }
            }
        }

        $result = Copy-Hashtable -InputObject $inHash

        $comparisonList = @(
            @{
                A        = $result.Value1
                B        = $outHash.Value1
                Operator = 'equal'
            }
            @{
                A        = $result.Value2
                B        = $outHash.Value2
                Operator = 'equal'
            }
            @{
                A        = $result.Ref1
                B        = $outHash.Ref1
                Operator = 'not equal'
            }
            @{
                A        = $result.Ref1.Value3
                B        = $outHash.Ref1.Value3
                Operator = 'equal'
            }
            @{
                A        = $result.Ref1.Value4
                B        = $outHash.Ref1.Value4
                Operator = 'equal'
            }
            @{
                A        = $result.Ref1.Value4
                B        = $outHash.Ref1.Value4
                Operator = 'equal'
            }
            @{
                A        = $result.Ref2
                B        = $outHash.Ref2
                Operator = 'not equal'
            }
            @{
                A        = $result.Ref2.Value5
                B        = $outHash.Ref2.Value5
                Operator = 'equal'
            }
            @{
                A        = $result.Ref2.Ref3
                B        = $outHash.Ref2.Ref3
                Operator = 'not equal'
            }
            @{
                A        = $result.Ref2.Ref3.Value6
                B        = $outHash.Ref2.Ref3.Value6
                Operator = 'equal'
            }
            @{
                A        = $result.Ref2.Ref3.Value7
                B        = $outHash.Ref2.Ref3.Value7
                Operator = 'equal'
            }
        )

        It '<A> is <Operator> to <B>' -TestCases $comparisonList {
            param($A, $B, $Operator)
            if ($Operator -eq 'equal') {
                $A | Should -BeExactly $B
            }
            elseif ($Operator -eq 'not equal') {
                $A | Should -Not -BeExactly $B
            }
            else { Write-Error "Invalid comparison operator '$($Operator)'" }
        }
    }
}