TestFixture "AstTests" {
	TestSetup {
		$Parent = Split-Path (Split-Path $PSCommandPath -Parent)
		Import-Module (Join-Path $Parent "PoshInternals.psd1") -Force
	}

	TestCase "RemoveExtentTest" {
		$tokens = $null 
		$errors = $null

		$scriptBlock = ConvertTo-Ast "{ param([ref][int]`$parameter) `$parameter }"
		$attribute = Get-Ast -Ast $scriptBlock -TypeConstraint -SearchNestedBlocks

		$attribute = $attribute[1]

		$actualBlock = Remove-Extent $scriptBlock $attribute.Extent -Verbose
		$expectedBlock = ConvertTo-Ast '{ param([ref]$parameter) $parameter }'

		$actualBlock.ToString() | Should be $expectedBlock.ToString()
	}
}