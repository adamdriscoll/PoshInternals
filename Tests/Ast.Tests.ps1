Describe "AstTests" {
	. (Join-Path $PSScriptRoot 'InitializeTest.ps1')

	Context "RemoveExtentTest" {
		$tokens = $null 
		$errors = $null

		$scriptBlock = ConvertTo-Ast "{ param([ref][int]`$parameter) `$parameter }"
		$attribute = Get-Ast -Ast $scriptBlock -TypeConstraint -SearchNestedBlocks

		$attribute = $attribute[1]

		$actualBlock = Remove-Extent $scriptBlock $attribute.Extent
		$expectedBlock = ConvertTo-Ast '{ param([ref]$parameter) $parameter }'

		It "should remove extent" {
			$actualBlock.ToString() | Should be $expectedBlock.ToString()
		}		
	}
}