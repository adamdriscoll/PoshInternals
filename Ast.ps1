function ConvertTo-Ast
{
	[CmdletBinding()]
	param([String]$String)

	Write-Debug $String

	$Tokens = $null 
	$Errors = $null

	[System.Management.Automation.Language.Parser]::ParseInput($String, [ref]$Tokens, [ref]$Errors)

	$Errors | % { Write-Error $_ }
}

function Get-Parameter 
{
	[CmdletBinding()]
	param(
	[Parameter(Mandatory, ValueFromPipeline=$true)]
	[System.Management.Automation.Language.ScriptBlockAst]$ScriptBlock
	)

	$ParamBlock = Get-Ast -ParamBlock -Ast $ScriptBlock
	Get-Ast -Parameter -Ast $ScriptBlock
}

function Get-Ast
{
	[CmdletBinding()]
	param(
	[Parameter(Mandatory)]
	[System.Management.Automation.Language.Ast]$Ast,
	[Switch]$Attribute,
	[Switch]$ParamBlock,
	[Switch]$Parameter,
	[Switch]$TypeConstraint,
	[Switch]$First,
	[Switch]$SearchNestedBlocks,
	[ScriptBlock]$Filter
	)

	$Predicate = {
		$this = $args[0]

		Write-Verbose "$this [$($this.GetType())]"

		if ($Attribute -and $this -is ([System.Management.Automation.Language.AttributeAst]))
		{
			if ($Filter -eq $null -or $Filter.Invoke($this))
			{
				Write-Output $this	
			}
		}
		if ($ParamBlock -and $this -is ([System.Management.Automation.Language.ParamBlockAst]))
		{
			if ($Filter -eq $null -or $Filter.Invoke($this))
			{
				Write-Output $this	
			}
		}
		if ($Parameter -and $this -is ([System.Management.Automation.Language.ParameterAst]))
		{
			if ($Filter -eq $null -or $Filter.Invoke($this))
			{
				Write-Output $this	
			}
		}
		if ($TypeConstraint -and $this -is ([System.Management.Automation.Language.TypeConstraintAst]))
		{
			if ($Filter -eq $null -or $Filter.Invoke($this))
			{
				Write-Output $this	
			}
		}
	}

	if ($First)
	{
		$Ast.Find($Predicate, $SearchNestedBlocks)
	}
	else
	{
		$Ast.FindAll($Predicate, $SearchNestedBlocks)
	}
}

function Remove-Extent 
{
	[CmdletBinding()]
	param([System.Management.Automation.Language.ScriptBlockAst]$ScriptBlock,
		  [System.Management.Automation.Language.IScriptExtent]$Extent)

	$ScriptBlockString = $ScriptBlock.ToString()

	Write-Verbose "Removing $($Extent.StartOffset) to $($Extent.EndOffset) in string of length $($ScriptBlockString.Length)"

	$ScriptBlockString = $ScriptBlockString.Remove($Extent.StartOffset, $Extent.EndOffset - $Extent.StartOffset)

	ConvertTo-Ast $ScriptBlockString
}
