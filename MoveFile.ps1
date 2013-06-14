<#
.Synopsis
    Schedules a file to be moved on reboot. 
.DESCRIPTION
    Schedules a file to be moved on reboot. This cmdlet can move a file on reboot and optionally
    replace an existing file. 
.EXAMPLE
   Move-FileOnReboot -Path "C:\Windows\System32\kernel32.dll" -Destination "C:\Windows\SysWow64\kernel32.dll" -ReplaceExisting
#>
function Move-FileOnReboot
{
    [CmdletBinding()]
    param(
    # The source file to move.
    [Parameter(Mandatory=$true)]
    [IO.FileInfo]$Path,
    # The destination to move the file to.
    [Parameter(Mandatory=$true)]
    [IO.FileInfo]$Destination,
    # Specifies whether to replace an existing file.
    [Parameter()]
    [Switch]$ReplaceExisting
    )

    Begin {    
        $Flags = [PoshInternals.MoveFileFlags]::MOVEFILE_DELAY_UNTIL_REBOOT

        if ($ReplaceExisting)
        {
            $flags = $flags -bor [PoshInternals.MoveFileFlags]::MOVEFILE_REPLACE_EXISTING
        }

        if ([PoshInternals.Kernel32]::MoveFileEx($Path, $Destination,  $flags) -eq 0)
        {
            throw New-Object System.Win32Exception
        }
    }
}

<#
.Synopsis
    Schedules a file to be deleted on reboot. 
.DESCRIPTION
    Schedules a file to be deleted on reboot. 
.EXAMPLE
   Remove-FileOnReboot -Path "C:\Windows\System32\kernel32.dll"
#>
function Remove-FileOnReboot
{
    [CmdletBinding()]
    param(
    [Parameter(Mandatory=$true)]
    [IO.FileInfo]$Path
    )

    Begin {    
        $Flags = [PoshInternals.MoveFileFlags]::MOVEFILE_DELAY_UNTIL_REBOOT

        if ([PoshInternals.Kernel32]::MoveFileEx($Path, $null, $Flags) -eq 0)
        {
            throw New-Object System.Win32Exception
        }
    }
}
