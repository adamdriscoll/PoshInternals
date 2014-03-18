$Global:ActiveHooks = New-Object -TypeName System.Collections.ArrayList

function Set-Hook {
	[CmdletBinding()]
	param(
	[Parameter()]
	[Switch]$Local,
	[Parameter(Mandatory)]
	[String]$Dll,
	[Parameter(Mandatory)]
	[String]$EntryPoint,
	[Parameter(Mandatory)]
	[Type]$ReturnType,
	[Parameter(Mandatory)]
	[ScriptBlock]$ScriptBlock,
	[Parameter()]
	[int]$ProcessId
	)

	function GenerateClass
	{
		param([String]$FunctionName, [String]$ReturnType, [ScriptBlock]$ScriptBlock)

		$PSParameters = @()
		foreach($parameter in $ScriptBlock.Ast.ParamBlock.Parameters)
		{
			$PSParameter = [PSCustomObject]@{Name=$parameter.Name.ToString().Replace("$", "");TypeName="";IsOut=$false}
			foreach($attribute in $parameter.Attributes)
			{
				if ($attribute.TypeName.Name -eq "ref")
				{
					$PSParameter.IsOut = $true
				}
				else
				{
					$PSParameter.TypeName = $attribute.TypeName.FullName
				}
			}
			$PSParameters += $PSParameter
		}

		$initializeSnippet = ""
		$outVarSnippet = ""
		$parameters = ""
		$parameterNames = ""

		$outVarIndex = 1
		foreach($PSParameter in $PSParameters)
		{
			$parameterNames += $PSParameter.Name + ","

			if ($PSParameter.IsOut)
			{
				$parameters += "[Out]"
				$outVarSnippet += "outVars[$outVarIndex];"
				$initializeSnippet += $PSParameter.Name + " = default($($PSParameter.TypeName));";
			}

			$parameters += $PSParameter.TypeName + " " + $PSParameter.Name + ","
		}

		if ($parameters.Length -gt 0)
		{
			$parameters = $parameters.Substring(0, $parameters.Length - 1)
			$parameterNames = $parameterNames.Substring(0, $parameterNames.Length - 1)
		}

		$Random = Get-Random -Minimum 0 -Maximum 100000

		@{
			ClassName = "Detour$Random";
			DelegateName = " $($FunctionName)_Delegate$Random";
			ClassDefinition = "
				using System.Runtime.InteropServices;
				using System.Management.Automation;
				using System.Management.Automation.Runspaces;

				[UnmanagedFunctionPointer(CallingConvention.StdCall, CharSet=CharSet.Unicode, SetLastError=true)]
				public delegate $ReturnType $($FunctionName)_Delegate$Random($parameters);

				public class Detour$Random 
				{
					public static ScriptBlock ScriptBlock;
					public static Runspace Runspace;

					public static $ReturnType $($FunctionName)_Hooked($parameters)
					{
						$initializeSnippet
						try 
						{
							Runspace.DefaultRunspace = Runspace;
							var outVars = ScriptBlock.Invoke($parameterNames);
							$outVarSnippet
							return ($ReturnType)outVars[0].BaseObject;
						}
						catch (System.Exception ex)
						{
							System.Console.WriteLine(ex.Message);
						}
						return default($ReturnType);
					}
				}
				";}
	}

	$ScriptDirectory = Split-Path $MyInvocation.MyCommand.Module.Path -Parent
	$Assembly = (Join-Path $ScriptDirectory "EasyHook\EasyHook.dll")
	Add-Type -Path $Assembly | Out-Null

	if ($Local)
	{
		$Class = GenerateClass -FunctionName $EntryPoint -ReturnType $ReturnType -ScriptBlock $ScriptBlock 
		Add-Type $Class.ClassDefinition

		Invoke-Expression "[$($Class.ClassName)]::Runspace = [System.Management.Automation.Runspaces.Runspace]::DefaultRunspace"
		Invoke-Expression "[$($Class.ClassName)]::ScriptBlock = `$ScriptBlock"
		$Delegate = Invoke-Expression "[$($Class.ClassName)].GetMember(`"$($EntryPoint)_Hooked`").CreateDelegate([Type]'$($Class.DelegateName)')"

		$Hook = [EasyHook.LocalHook]::Create([EasyHook.LocalHook]::GetProcAddress($DLL, $EntryPoint), $Delegate, $null)
		$Hook.ThreadACL.SetExclusiveACL([int[]]@(1))

		$FriendlyHook = [PSCustomObject]@{RawHook=$Hook;Dll=$Dll;EntryPoint=$EntryPoint}

		$FriendlyHook = $FriendlyHook | Add-Member -MemberType ScriptMethod -Value {$Global:ActiveHooks.Remove($this);$this.RawHook.Dispose();} -Name "Remove" -PassThru
			
		$FriendlyHook

		$Global:ActiveHooks.Add($FriendlyHook)
	}
	else
	{
		$ModulePath = $MyInvocation.MyCommand.Module.Path
		$Global:HookServer = [PoshInternals.HookInterface]::CreateServer()
		[PoshInternals.HookInterface]::Inject($ProcessId, $EntryPoint, $Dll, $ReturnType.FullName, $ScriptBlock.ToString(), $ModulePath);
	}
}

function Get-Hook 
{
	param([String]$EntryPoint, [String]$Dll)

	$Hooks = $Global:ActiveHooks.Clone()
	
	if (-not [String]::IsNullOrEmpty($EntryPoint))
	{
		$Hooks = $Hooks | Where EntryPoint -Like $EntryPoint
	}

	if (-not [String]::IsNullOrEmpty($Dll))
	{
		$Hooks = $Hooks | Where Dll -Like $Dll
	}

	$Hooks
}

function Remove-Hook
{
	[CmdletBinding()]
	param([Parameter(ValueFromPipeline=$true)][Object]$Hook, 
		  [Parameter()][String]$EntryPoint, 
		  [Parameter()][String]$Dll)
	
	Begin {
		if ($EntryPoint -ne $null -or $Dll -ne $null)
		{
			$Hook = Get-Hook -EntryPoint $EntryPoint  -Dll $Dll
		}
	}

	Process {
		$Hook.Remove()
	}
}