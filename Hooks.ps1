$Script:ActiveHooks = New-Object -TypeName System.Collections.ArrayList

function Set-Hook {
	[CmdletBinding()]
	param(
	[Parameter(Mandatory)]
	[String]$Dll,
	[Parameter(Mandatory)]
	[String]$EntryPoint,
	[Parameter(Mandatory)]
	[Type]$ReturnType,
	[Parameter(Mandatory)]
	[ScriptBlock]$ScriptBlock,
	[Parameter()]
	[int]$ProcessId = $PID,
	[Parameter()]
	[String]$AdditionalCode
	)

	$Assembly = [System.Reflection.Assembly]::LoadWithPartialName("PoshHook");
	if ($Assembly  -eq $null)
	{
		throw new-object System.Exception -ArgumentList "PoshHook is not initialized. Run Initialize-PoshHook."
	}

	function FixupScriptBlock
	{
		param($ScriptBlock)
		
		Write-Debug  $ScriptBlock.ToString()

		$ScriptBlock = ConvertTo-Ast $ScriptBlock.ToString().Trim("{","}")

		$RefArg = Get-Ast -SearchNested -Ast $ScriptBlock -TypeConstraint -Filter { 
			$args[0].TypeName.Name -eq "ref" 
		} 

		if ($RefArg)
		{
			$constraints = Get-Ast -Ast $ScriptBlock -TypeConstraint -SearchNested
			foreach($constraint in $constraints)
			{
				if ($constraint.TypeName.Name -ne "ref")
				{
					$ScriptBlock = Remove-Extent -ScriptBlock $ScriptBlock -Extent $constraint.Extent
					return FixupScriptBlock $ScriptBlock
				} 
			}
		}

		$ScriptBlock
	}

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

		$initRef = ""
		$preRef = ""
		$postRef = ""

		$parameters = ""
		$parameterNames = ""
		foreach($PSParameter in $PSParameters)
		{
			$parameterNames += $PSParameter.Name + ","

			if ($PSParameter.IsOut)
			{
				$parameters += "out "
				$parameterNamesForSb += "$($PSParameter.Name)ref,"

				$initRef += "$($PSParameter.Name) = default($($PSParameter.TypeName)); `n"
				$preRef  += "var $($PSParameter.Name)ref = new PSReference($($PSParameter.Name)); `n"
				$postRef  += "$($PSParameter.Name) = ($($PSParameter.TypeName))$($PSParameter.Name)ref.Value; `n"

			}
			else
			{
				$parameterNamesForSb += $PSParameter.Name + ","
			}

			$parameters += $PSParameter.TypeName + " " + $PSParameter.Name + ","
		}

		if ($parameters.Length -gt 0)
		{
			$parameters = $parameters.Substring(0, $parameters.Length - 1)
			$parameterNames = $parameterNames.Substring(0, $parameterNames.Length - 1)
			$parameterNamesForSb = $parameterNamesForSb.Substring(0, $parameterNamesForSb.Length - 1)
		}

		$Random = Get-Random -Minimum 0 -Maximum 100000

		$ReturnStatement = ""
		$DefaultReturnStatement = ""
		if ($ReturnType -ne ([void]))
		{
			$ReturnStatement = "return ($ReturnType)outVars[0].BaseObject;";
			$DefaultReturnStatement = "return default($ReturnType);"
		}

		@{
			ClassName = "Detour$Random";
			DelegateName = " $($FunctionName)_Delegate$Random";
			ClassDefinition = "
				using System.Runtime.InteropServices;
				using System.Management.Automation;
				using System.Management.Automation.Runspaces;

				$AdditionalCode

				[UnmanagedFunctionPointer(CallingConvention.StdCall, CharSet=CharSet.Unicode, SetLastError=true)]
				public delegate $ReturnType $($FunctionName)_Delegate$Random($parameters);

				public class Detour$Random 
				{
					public static ScriptBlock ScriptBlock;
					public static Runspace Runspace;

					public static $ReturnType $($FunctionName)_Hooked($parameters)
					{
						$initRef
						try 
						{ 
							Runspace.DefaultRunspace = Runspace;

							$preRef
							var outVars = ScriptBlock.Invoke($parameterNamesForSb);
							$postRef

							$ReturnStatement
						}
						catch (System.Exception ex)
						{
							System.Console.WriteLine(ex.Message);
						}
						$DefaultReturnStatement
					}
				}
				";}
	}

	$ScriptDirectory = Split-Path $MyInvocation.MyCommand.Module.Path -Parent
	[Reflection.Assembly]::LoadWithPartialName("EasyHook") | Out-Null

	if ($ProcessId -eq $PID)
	{
		$Class = GenerateClass -FunctionName $EntryPoint -ReturnType $ReturnType -ScriptBlock $ScriptBlock 
		$ScriptBlock = (FixupScriptBlock $ScriptBlock.Ast).GetScriptBlock()

		Write-Verbose $Class.ClassDefinition

		Add-Type $Class.ClassDefinition

		Invoke-Expression "[$($Class.ClassName)]::Runspace = [System.Management.Automation.Runspaces.Runspace]::DefaultRunspace"
		Invoke-Expression "[$($Class.ClassName)]::ScriptBlock = `$ScriptBlock"
		$Delegate = Invoke-Expression "[$($Class.ClassName)].GetMember(`"$($EntryPoint)_Hooked`").CreateDelegate([Type]'$($Class.DelegateName)')"

		$Hook = [EasyHook.LocalHook]::Create([EasyHook.LocalHook]::GetProcAddress($DLL, $EntryPoint), $Delegate, $null)
		$Hook.ThreadACL.SetExclusiveACL([int[]]@(1))

		$FriendlyHook = [PSCustomObject]@{RawHook=$Hook;Dll=$Dll;EntryPoint=$EntryPoint}

		$FriendlyHook = $FriendlyHook | Add-Member -MemberType ScriptMethod -Value {$Global:ActiveHooks.Remove($this);$this.RawHook.Dispose();} -Name "Remove" -PassThru
			
		$FriendlyHook

		$Script:ActiveHooks.Add($FriendlyHook)
	}
	else
	{
		[Reflection.Assembly]::LoadWithPartialName("PoshHook") | Out-Null

		if ([IntPtr]::Size -eq 4)
		{
			[PoshInternals.Kernel32]::LoadLibrary((Join-Path $ScriptDirectory "EasyHook\EasyHook32.dll"))
		}
		else
		{
			[PoshInternals.Kernel32]::LoadLibrary((Join-Path $ScriptDirectory "EasyHook\EasyHook64.dll"))
		}
		
		Push-Location 
		Set-Location (Join-Path $ScriptDirectory "EasyHook")

		$ModulePath = $MyInvocation.MyCommand.Module.Path

		if ($Script:HookServer -eq $null)
		{
			$Script:HookServer = [PoshInternals.HookInterface]::CreateServer()
		}
		
		[PoshInternals.HookInterface]::Inject($ProcessId, $EntryPoint, $Dll, $ReturnType.FullName, $ScriptBlock.ToString(), $ModulePath)

		Pop-Location
	}
}

function Get-Hook 
{
	param([String]$EntryPoint, [String]$Dll)

	$Hooks = $Script:ActiveHooks.Clone()
	
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

function Initialize-PoshHook 
{
	$Assembly = [System.Reflection.Assembly]::LoadWithPartialName("PoshHook")
	if ($Assembly -ne $null)
	{	
		Write-Warning "PoshHooks already initialized."
		return
	}

	Add-Type -AssemblyName System.EnterpriseServices 
	$Publish = New-Object System.EnterpriseServices.Internal.Publish

	$EasyHookPath = (Join-Path $ScriptDirectory "EasyHook\EasyHook.dll")
	$Publish.GacInstall($EasyHookPath)

	$EasyHook = [System.Reflection.Assembly]::LoadWithPartialName("EasyHook")

	$HookPath = (Join-Path ([IO.Path]::GetTempPath()) "PoshHook.dll")
	$CompilerParameters = New-Object System.CodeDom.Compiler.CompilerParameters
	$CompilerParameters.CompilerOptions = "/keyfile:`"$((Join-Path $ScriptDirectory "PoshInternals.snk"))`""
	$CompilerParameters.ReferencedAssemblies.Add($EasyHook.Location) | Out-Null
	$CompilerParameters.ReferencedAssemblies.Add([System.Management.Automation.Cmdlet].Assembly.Location) | Out-Null
	$CompilerParameters.ReferencedAssemblies.Add("System.dll") | Out-Null
	$CompilerParameters.ReferencedAssemblies.Add("System.Core.dll") | Out-Null
	$CompilerParameters.ReferencedAssemblies.Add("System.Runtime.Remoting.dll") | Out-Null
	$CompilerParameters.OutputAssembly = $HookPath

	Add-Type -Path (Join-Path $ScriptDirectory "HookInject.cs") -CompilerParameters $CompilerParameters | Out-Null 
	
	$Publish.GacInstall($HookPath)
}

function Uninitialize-PoshHook {
	Add-Type -AssemblyName System.EnterpriseServices 
	$Publish = New-Object System.EnterpriseServices.Internal.Publish

	$Assembly = [System.Reflection.Assembly]::LoadWithPartialName("PoshHook")
	if ($Assembly -ne $null)
	{
		$Publish.GacRemove($Assembly.Location)
	}

	$Assembly = [System.Reflection.Assembly]::LoadWithPartialName("EasyHook")
	if ($Assembly -ne $null)
	{
		$Publish.GacRemove($Assembly.Location)
	}
	
}