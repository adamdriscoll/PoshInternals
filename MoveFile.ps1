function Move-FileOnReboot
{
    [CmdletBinding()]
    param(
    [Parameter(Mandatory=$true)]
    [IO.FileInfo]$Path,
    [Parameter(Mandatory=$true)]
    [IO.FileInfo]$Destination,
    [Parameter()]
    [Switch]$ReplaceExisting
    )

    Begin {    
        $Flags = [PoshInternals.MoveFileFlags]::MOVEFILE_DELAY_UNTIL_REBOOT

        if ($ReplaceExisting)
        {
            $flags = $flags -bor [PoshInternals.MoveFileFlags]::MOVEFILE_REPLACE_EXISTING
        }

        if ([PoshInternals.NativeMethods]::MoveFileEx($Path, $Destination,  $flags) -eq 0)
        {
            throw New-Object System.Win32Exception
        }
    }
}

function Remove-FileOnReboot
{
    [CmdletBinding()]
    param(
    [Parameter(Mandatory=$true)]
    [IO.FileInfo]$Path,
    [Parameter()]
    [Switch]$Force
    )

    Begin {    
        $Flags = [PoshInternals.MoveFileFlags]::MOVEFILE_DELAY_UNTIL_REBOOT

        if ([PoshInternals.NativeMethods]::MoveFileEx($Path, $null, $Flags) -eq 0)
        {
            throw New-Object System.Win32Exception
        }
    }
}
