function Out-MiniDump
{
    [CmdletBinding()]
    param(
    [Parameter(ValueFromPipeline=$True, Mandatory=$true)]
    [System.Diagnostics.Process]$Process,
    [Parameter()]
    [string]$Path,
    [Parameter()]
    [Switch]$Full
    )

    Process
    {
        if ([String]::IsNullOrEmpty($Path))
        {
            $Path = Join-Path ([Environment]::CurrentDirectory) "$($Process.ID).dmp"
        }

        if ($Full)
        {
            $DumpType = [PoshInternals.MINIDUMP_TYPE]::MiniDumpWithFullMemory
        }
        else
        {
            $DumpType = [PoshInternals.MINIDUMP_TYPE]::MiniDumpNormal
        }

        $FileName = [PoshInternals.NativeMethods]::CreateFile($Path, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None, [IntPtr]::Zero, [System.IO.FileMode]::CreateNew, 0, [IntPtr]::Zero)
        if ($FileName.IsInvalid)
        {
            throw New-Object System.ComponentModel.Win32Exception
        }

        if (-not [PoshInternals.NativeMethods]::MiniDumpWriteDump($Process.Handle, $Process.Id, $FileName, $DumpType, [IntPtr]::Zero, [IntPtr]::Zero, [IntPtr]::Zero))
        {
            throw New-Object System.ComponentModel.Win32Exception
        }
        

    }
}

