function Watch-Process
{
    [CmdletBinding()]
    param(
    [Parameter(ValueFromPipeline=$True)]
    [System.Diagnostics.Process]$Process
    )

    Process
    {
        $DumpFile = Join-Path ([Environment]::CurrentDirectory) "$($Process.ID).dmp"

        $FileName = [PoshInternals.NativeMethods]::CreateFile($DumpFile, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None, [IntPtr]::Zero, [System.IO.FileMode]::CreateNew, 0, [IntPtr]::Zero)
        if ($FileName.IsInvalid)
        {
            throw New-Object System.ComponentModel.Win32Exception
        }

        if (-not [PoshInternals.NativeMethods]::MiniDumpWriteDump($Process.Handle, $Process.Id, $FileName, [PoshInternals.MINIDUMP_TYPE]::MiniDumpWithFullMemory, [IntPtr]::Zero, [IntPtr]::Zero, [IntPtr]::Zero))
        {
            throw New-Object System.ComponentModel.Win32Exception
        }
    }
}

