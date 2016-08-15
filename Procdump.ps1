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
            $Path = Join-Path (Get-Location) "$($Process.ID)_$MS.dmp"
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

		$FileStream = $null
		try 
		{
			Write-Verbose "Dump File Path [$Path]"
			$FileStream = New-Object -TypeName System.IO.FileStream -ArgumentList $Path,'CreateNew','Write','None'
		}
		catch 
		{
			Write-Error $_
			return
		}
        
        if (-not $FileStream)
        {
            throw New-Object System.ComponentModel.Win32Exception
        }

        if (-not [PoshInternals.DbgHelp]::MiniDumpWriteDump($Process.Handle, $Process.Id, $FileStream.Handle, $DumpType, [IntPtr]::Zero, [IntPtr]::Zero, [IntPtr]::Zero))
        {
			$FileStream.Dispose()
            throw New-Object System.ComponentModel.Win32Exception
        }
        
		$FileStream.Dispose()
    }
}

