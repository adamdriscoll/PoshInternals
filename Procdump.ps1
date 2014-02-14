<#
.Synopsis
    Writes a minidump for the specified process.
.DESCRIPTION
    Writes a minidump for the specified process. When no path is specified the dump will be placed
    in the current directory with the name of the process and a time stamp.
.EXAMPLE
   Get-Process Notepad | Out-MiniDump -Path C:\MyDump.dmp -Full
#>
function Out-MiniDump
{
    [CmdletBinding()]
    param(
    # The process to take a memory dump of.
    [Parameter(ValueFromPipeline=$True, Mandatory=$true)]
    [System.Diagnostics.Process]$Process,
    # The path output the minidump to
    [Parameter()]
    [string]$Path,
    # Whether to take a full memory dump
    [Parameter()]
    [Switch]$Full,
	# Force the overwrite of an existing dump
    [Parameter()]
    [Switch]$Force
    )

    Process
    {
        if ([String]::IsNullOrEmpty($Path))
        {
            $MS = [DateTime]::Now.Millisecond
            $Path = Join-Path ([Environment]::CurrentDirectory) "$($Process.ID)_$MS.dmp"
        }
		
		if (-not $Force -and (Test-Path $Path))
		{
			throw "$Path already exists. Use the -Force parameter to overwrite and existing dmp file."
		}
		elseif ($Force -and (Test-Path $Path))
		{
			Remove-Item $Path -Force | Out-Null
		}

        if ($Full)
        {
            $DumpType = [PoshInternals.MINIDUMP_TYPE]::MiniDumpWithFullMemory
        }
        else
        {
            $DumpType = [PoshInternals.MINIDUMP_TYPE]::MiniDumpNormal
        }

        $FileName = [PoshInternals.Kernel32]::CreateFile($Path, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None, [IntPtr]::Zero, [System.IO.FileMode]::CreateNew, 0, [IntPtr]::Zero)
        if ($FileName.IsInvalid)
        {
            throw New-Object System.ComponentModel.Win32Exception
        }

        if (-not [PoshInternals.DbgHelp]::MiniDumpWriteDump($Process.Handle, $Process.Id, $FileName, $DumpType, [IntPtr]::Zero, [IntPtr]::Zero, [IntPtr]::Zero))
        {
			[PoshInternals.Kernel32]::CloseHandle($FileName)
            throw New-Object System.ComponentModel.Win32Exception
        }
        
		[PoshInternals.Kernel32]::CloseHandle($FileName)
    }
}

