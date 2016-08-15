<#
.Synopsis
    Gets open system handles.
.DESCRIPTION
   Gets open system handles. This cmdlet can filter by process and handle name. 
.EXAMPLE
   Get-Process Notepad | Get-Handle
.EXAMPLE
   Get-Handle -Name "*myfile.txt"
#>
function Get-Handle
{
    [CmdletBinding()]
    param(
    # A process to return open handles for.
    [Parameter(ValueFromPipeline=$true)]
    [System.Diagnostics.Process]$Process,
    # The name of the handle
	[Parameter()]
    [String]$Name = $null,
	[Parameter()]
	[ValidateSet("File", "Directory")]
	[String]$Type = $null

    )

	Begin {
		#$Handles =
	}

    Process {
	 Get-AllHandles

        #if ($Process -ne $Null)
        #{
        #    $Handles | Where-Object { $_.ProcessId -eq $Process.Id -and $_.Name -match $Name} 
        #}
        #elseif ($Name -ne $null)
        #{
        #    $Handles |  Where-Object { $_.Name -like $Name} 
        #}
        #else
        #{
        #    $Handles
        #}
    }
}

<#
.Synopsis
    Closes open system handles.
.DESCRIPTION
   Closes open system handles. This cmdlet can cause system instability.
.EXAMPLE
   Get-Process Notepad | Get-Handle | Close-Handle
.EXAMPLE
   Get-Handle -Name "*myfile.txt" | Close-Handle
#>
function Close-Handle
{
    [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='High')]
    param(
    [Parameter(ValueFromPipeline=$true)]
    $Handle
    )

    Process
    {
        if ($PSCmdlet.ShouldProcess($Handle.Name,"Closing a handle can cause system instability. Close handle?"))
        {
            $Handle.Close()
        }
    }
}

<#
.SYNOPSIS

Converts a DOS-style file name into a regular Windows file name.
.DESCRIPTION



This function can convert a DOS-style (\Device\HarddiskVolume1\MyFile.txt) file name into a regular Windows (C:\MyFile.txt)
file name. 

.PARAMETER RawFileName

The DOS-style file name.

.EXAMPLE

ConvertTo-RegularFileName -RawFileName "\Device\HarddiskVolume1\MyFile.txt"

#>
function ConvertTo-RegularFileName
{
	param($RawFileName)

    foreach ($logicalDrive in [Environment]::GetLogicalDrives())
    {
        $targetPath = New-Object System.Text.StringBuilder 256
        if ([PoshInternals.Kernel32]::QueryDosDevice($logicalDrive.Substring(0, 2), $targetPath, 256) -eq 0)
        {
            return $targetPath
        }
        $targetPathString = $targetPath.ToString()
        if ($RawFileName.StartsWith($targetPathString))
        {
            $RawFileName = $RawFileName.Replace($targetPathString, $logicalDrive.Substring(0, 2))
            break
        }
    }
    $RawFileName
}

<#
.SYNOPSIS

Converts a SystemHandleEntry into a PSCustomObject.
.DESCRIPTION

This function is intended to convert a SystemHandleEntry returned by
Get-FileHandle into a PSCustomObject that exposes a Process property and a
file name. 

.PARAMETER HandleEntry

The SystemHandleEntry as returned by Get-FileHandle

.EXAMPLE

Get-FileHandle | ConvertTo-HandleHashTable
#>
function ConvertTo-HandleHashTable
{
	[CmdletBinding()]
	param(
		[Parameter(Mandatory, ValueFromPipeline=$true)]
		$HandleEntry,
		[Parameter(Mandatory)]
		[IntPtr]$ProcessHandle
	)

	Process
	{
		if ($HandleEntry.GrantedAccess -eq 0x0012019f -or $HandleEntry.GrantedAccess -eq 0x00120189 -or $HandleEntry.GrantedAccess -eq 0x120089)
		{
			return
		}

		$HandleType = Find-HandleType -HandleEntry $HandleEntry -ProcessHandle $ProcessHandle

		$length = 0
		$Result = [PoshInternals.NtDll]::NtQueryObject($ProcessHandle, 'ObjectNameInformation', [IntPtr]::Zero, 0, [ref]$length) 
		$ptr = [IntPtr]::Zero

		if ($Result -ne [PoshInternals.NT_STATUS]::STATUS_INFO_LENGTH_MISMATCH)
		{
			return
		}

		try 
		{
			$ptr = [Runtime.InteropServices.Marshal]::AllocHGlobal($length)
			if ([PoshInternals.NtDll]::NtQueryObject($ProcessHandle, 'ObjectNameInformation', $ptr, $length, [ref]$length) -ne [PoshInternals.NT_STATUS]::STATUS_SUCCESS)
			{
				return
			}

			$Path = [Runtime.InteropServices.Marshal]::PtrToStringUni([IntPtr]([long]$ptr + 2 * [IntPtr]::Size))

			if ($HandleType -eq "File" -or $HandleType -eq "Directory")
			{
				$Path = ConvertTo-RegularFileName $Path
			}

			$PsObject = [PSCustomObject]@{
				Type=$HandleType;
				Path=$Path;
				Process=$HandleEntry.OwnerProcessId;
			}
			
			return $PsObject
		}
		catch 
		{
			Write-Warning $_.Exception.Message
		}
		finally 
		{
			[Runtime.InteropServices.Marshal]::FreeHGlobal($ptr)
		}
	}
}

$HandleTypeCache = @{}

function Find-HandleType {
	param( 
	    [Parameter(Mandatory)]
		$HandleEntry,
		[Parameter(Mandatory)]
		[IntPtr]$ProcessHandle)

	if ($HandleTypeCache.ContainsKey($HandleEntry.ObjectTypeNumber))
	{
		return $HandleTypeCache[$HandleEntry.ObjectTypeNumber]
	}

	$length = 0
    $Result = [PoshInternals.NtDll]::NtQueryObject($ProcessHandle, 'ObjectTypeInformation', [IntPtr]::Zero, 0, [ref] $length)
    $ptr = [IntPtr]::Zero

	if ($Result -ne [PoshInternals.NT_STATUS]::STATUS_INFO_LENGTH_MISMATCH)
	{
		return
	}

    try
    {
        $ptr = [Runtime.InteropServices.Marshal]::AllocHGlobal($length)
        if ([PoshInternals.NtDll]::NtQueryObject($ProcessHandle, 'ObjectTypeInformation', $ptr, $length, [ref] $length) -ne [PoshInternals.NT_STATUS]::STATUS_SUCCESS)
		{
			return
		}
             
        $typeStr = [Runtime.InteropServices.Marshal]::PtrToStringUni([IntPtr]([long]$ptr + 0x58 + 2 * [IntPtr]::Size))
        $HandleTypeCache[$HandleEntry.ObjectTypeNumber] = $typeStr 

		$typeStr
    }
	catch
	{
		Write-Warning $_.Exception.Message
	}
    finally
    {
        [Runtime.InteropServices.Marshal]::FreeHGlobal($ptr)
    }
}

<#
.SYNOPSIS

Returns open file handles found on the system. 
.DESCRIPTION

This function returns all open file handles found on the system. In its current state
this cmdlet will only work on a Windows 8 machine.

.EXAMPLE

Get-Handle
#>
function Get-AllHandles
{
    param($Type)

    $length = 0x10000
    $ptr = [IntPtr]::Zero
    try
    {
        while ($true)
        {
            $ptr = [Runtime.InteropServices.Marshal]::AllocHGlobal($length)
            $wantedLength = 0
			[PoshInternals.SYSTEM_INFORMATION_CLASS]$HandleInfo = 'SystemHandleInformation'
            $result = [PoshInternals.NtDll]::NtQuerySystemInformation($HandleInfo, $ptr, $length, [ref] $wantedLength)
            if ($result -eq [PoshInternals.NT_STATUS]::STATUS_INFO_LENGTH_MISMATCH)
            {
                $length = [Math]::Max($length, $wantedLength)
                [Runtime.InteropServices.Marshal]::FreeHGlobal($ptr)
                $ptr = [IntPtr]::Zero
            }
            elseif ($result -eq [PoshInternals.NT_STATUS]::STATUS_SUCCESS)
			{
                break
			}
            else
			{
                throw (New-Object System.ComponentModel.Win32Exception)
			}
        }

		if ([IntPtr]::Size -eq 4)
		{
			$handleCount = [Runtime.InteropServices.Marshal]::ReadInt32($ptr)
		}
		else
		{
			$handleCount = [Runtime.InteropServices.Marshal]::ReadInt64($ptr)
		}

		if ($handleCount -gt [Int32]::MaxValue)
		{
			Write-Error "Handle count too large!"
			continue
		}

		$She = New-Object -TypeName PoshInternals.SystemHandleEntry
        $size = [Runtime.InteropServices.Marshal]::SizeOf($She)

		$CurrentProcessHandle = (Get-Process -Id $Pid).Handle

		$ClassName = "StructArray$(Get-Random -Minimum 1 -Maximum 10000)"
		$StructName = "Struct$(Get-Random -Minimum 1 -Maximum 10000)"

		Add-Type -TypeDefinition "
			using System.Runtime.InteropServices;

			[StructLayout(LayoutKind.Sequential)]
			public struct $StructName
			{
				public int OwnerProcessId;
				public byte ObjectTypeNumber;
				public byte Flags;
				public ushort Handle;
				public System.IntPtr Object;
				public int GrantedAccess;
			}

			[StructLayout(LayoutKind.Sequential)]
			public struct $ClassName
			{
				[MarshalAsAttribute(UnmanagedType.ByValArray, SizeConst = $HandleCount, ArraySubType = UnmanagedType.Struct)]
				public $StructName [] Entries;
			}
		"

		$HandleArray = New-Object -TypeName $ClassName
		$HandleArray = [Runtime.InteropServices.Marshal]::PtrToStructure([IntPtr]([long]$ptr + [IntPtr]::Size), [Type]$HandleArray.GetType())

        for ($i = 0; $i -lt $handleCount; $i++)
        {
			$HandleEntry = $HandleArray.Entries[$i]

			$sourceProcessHandle = [IntPtr]::Zero
			$handleDuplicate = [IntPtr]::Zero
			$sourceProcessHandle = [PoshInternals.Kernel32]::OpenProcess(0x40, $true, $HandleEntry.OwnerProcessId)
			if ($sourceProcessHandle -eq [IntPtr]::Zero)
			{
				continue
			}

			if (-not [PoshInternals.Kernel32]::DuplicateHandle($sourceProcessHandle, [IntPtr]$HandleEntry.Handle, $CurrentProcessHandle, [ref]$handleDuplicate, 0, $false, 2))
			{
				continue
			}

			$HandleEntry | ConvertTo-HandleHashTable -ProcessHandle $handleDuplicate
        }
    }
    finally
    {
        if ($ptr -ne [IntPtr]::Zero)
		{
            [System.Runtime.InteropServices.Marshal]::FreeHGlobal($ptr)
		}
    }
}