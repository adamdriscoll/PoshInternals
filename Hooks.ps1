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
	[String]$AdditionalCode,
	[Parameter()]
	[Switch]$Log
	)

	$Assembly = [System.Reflection.Assembly]::LoadWithPartialName("PoshHook");
	if ($Assembly  -eq $null)
	{
		throw new-object System.Exception -ArgumentList "PoshHook is not initialized. Run Register-PoshHook ."
	}

	function FixupScriptBlock
	{
		param($ScriptBlock, $ClassName)
		
		Write-Debug  $ScriptBlock.ToString()

		$ScriptBlock = ConvertTo-Ast $ScriptBlock.ToString().Trim("{","}").Replace("[Detour]", "[$ClassName]")

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
		param([String]$FunctionName, [String]$ReturnType, [ScriptBlock]$ScriptBlock, [String]$Dll, [String]$AdditionalCode)

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
				using System;
				using System.Runtime.InteropServices;
				using System.Management.Automation;
				using System.Management.Automation.Runspaces;

				$AdditionalCode

				[UnmanagedFunctionPointer(CallingConvention.StdCall, CharSet=CharSet.Unicode, SetLastError=true)]
				public delegate $ReturnType $($FunctionName)_Delegate$Random($parameters);

				public class Detour$Random 
				{
					[DllImport(`"$Dll`", CharSet=CharSet.Unicode, SetLastError=true)]
					public static extern $ReturnType $($FunctionName)($parameters);

					public static ScriptBlock ScriptBlock;
					public static Runspace Runspace;

					public static $ReturnType $($FunctionName)_Hooked($parameters)
					{
						$initRef
						try 
						{ 
							Runspace.DefaultRunspace = Runspace;
							Runspace.DefaultRunspace.SessionStateProxy.SetVariable(`"$FunctionName`", typeof(Detour$Random).GetMethod(`"$FunctionName`"));

							$preRef
							var outVars = ScriptBlock.Invoke($parameterNamesForSb);
							$postRef

							Log(outVars[0].BaseObject.ToString());

							$ReturnStatement
						}
						catch (System.Exception ex)
						{
							Log(ex.Message);
						}
						$DefaultReturnStatement
					}

					private static void Log(string message)
					{
						try
						{
							if (!System.Diagnostics.EventLog.SourceExists(`"PoshHook`"))
							{
								System.Diagnostics.EventLog.CreateEventSource(`"PoshHook`", `"Application`");
							}
                
							var log = new System.Diagnostics.EventLog(`"Application`", `".`", `"PoshHook`");
							log.WriteEntry(message);
						}
						catch
						{
                
						}
					}
				}
				";}
	}

	$ScriptDirectory = Split-Path $MyInvocation.MyCommand.Module.Path -Parent
	[Reflection.Assembly]::LoadWithPartialName("EasyHook") | Out-Null

	$DepPath = (Join-Path $ScriptDirectory "EasyHook")
	Write-Verbose "Set EasyHook Dependency Path to $DepPath"
	[EasyHook.Config]::DependencyPath = $DepPath

	if ($ProcessId -eq $PID)
	{
		if ([IntPtr]::Size -eq 4)
		{
			[PoshInternals.Kernel32]::LoadLibrary((Join-Path $ScriptDirectory "EasyHook\EasyHook32.dll"))
		}
		else
		{
			[PoshInternals.Kernel32]::LoadLibrary((Join-Path $ScriptDirectory "EasyHook\EasyHook64.dll"))
		}

		$Class = GenerateClass -FunctionName $EntryPoint -ReturnType $ReturnType -ScriptBlock $ScriptBlock -Dll $Dll -AdditionalCode $AdditionalCode 

		Write-EventLog -LogName "Application" -Source "PoshHook" -Message $Class.ClassDefinition -EventId 1

		$ScriptBlock = (FixupScriptBlock $ScriptBlock.Ast $Class.ClassName).GetScriptBlock()

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
			Write-Verbose "Loading EasyHook32.dll..."
			[PoshInternals.Kernel32]::LoadLibrary((Join-Path $ScriptDirectory "EasyHook\EasyHook32.dll"))
		}
		else
		{
			Write-Verbose "Loading EasyHook64.dll..."
			[PoshInternals.Kernel32]::LoadLibrary((Join-Path $ScriptDirectory "EasyHook\EasyHook64.dll"))
		}
		
		$ModulePath = $MyInvocation.MyCommand.Module.Path

		if ($Script:HookServer -eq $null)
		{
			Write-Verbose "Creating HookInterface server..."
			$Script:HookServer = [PoshInternals.HookInterface]::CreateServer()
		}
		
		Write-Verbose "Injecting remote hook..."
		[PoshInternals.HookInterface]::Inject($ProcessId, $EntryPoint, $Dll, $ReturnType.FullName, $ScriptBlock.ToString(), $ModulePath, $AdditionalCode, $Log)
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

function Register-PoshHook 
{
	if (-not (Test-Elevated))
	{
		throw "This command requires elevation."
	}

	$Assembly = [System.Reflection.Assembly]::LoadWithPartialName("PoshHook")
	if ($Assembly -ne $null)
	{	
		Write-Warning "PoshHooks already initialized."
		return
	}

	Add-Type -AssemblyName System.EnterpriseServices 
	$Publish = New-Object System.EnterpriseServices.Internal.Publish

	$EasyHookPath = (Join-Path $PSScriptRoot "EasyHook\EasyHook.dll")
	$Publish.GacInstall($EasyHookPath)

	$EasyHook = [System.Reflection.Assembly]::LoadWithPartialName("EasyHook")

	$HookPath = (Join-Path ([IO.Path]::GetTempPath()) "PoshHook.dll")
	$CompilerParameters = New-Object System.CodeDom.Compiler.CompilerParameters
	$CompilerParameters.CompilerOptions = "/keyfile:`"$((Join-Path $PSScriptRoot "PoshInternals.snk"))`""
	$CompilerParameters.ReferencedAssemblies.Add($EasyHook.Location) | Out-Null
	$CompilerParameters.ReferencedAssemblies.Add([System.Management.Automation.Cmdlet].Assembly.Location) | Out-Null
	$CompilerParameters.ReferencedAssemblies.Add("System.dll") | Out-Null
	$CompilerParameters.ReferencedAssemblies.Add("System.Core.dll") | Out-Null
	$CompilerParameters.ReferencedAssemblies.Add("System.Runtime.Remoting.dll") | Out-Null
	$CompilerParameters.OutputAssembly = $HookPath

	Add-Type -Path (Join-Path $PSScriptRoot "HookInject.cs") -CompilerParameters $CompilerParameters | Out-Null 
	
	$Publish.GacInstall($HookPath)
}

function Unregister-PoshHook {
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

function Test-Elevated {
	$identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
	$principal = New-Object  System.Security.Principal.WindowsPrincipal -ArgumentList $identity
	$principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}