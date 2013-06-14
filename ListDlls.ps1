<#
.Synopsis
    Gets the DLLs loaded by processes on the system.
.DESCRIPTION
   Gets the DLLs loaded by processes on the system.
.EXAMPLE
   Get-Dll -ProcessName Notepad
.EXAMPLE
   Get-Dll -ModuleName mydll.dll
#>
function Get-Dll
{
    [CmdletBinding()]
    param(
    # The process to get the DLLs of 
    [Parameter(ValueFromPipeline=$true, ParameterSetName="Process")]
    [System.Diagnostics.Process]$Process,
    # The process name to get the DLLs of
    [Parameter(ValueFromPipeline=$true, ParameterSetName="ProcessName")]
    [String]$ProcessName = "",
    # The process ID to get the DLLs of
    [Parameter(ValueFromPipeline=$true, ParameterSetName="ProcessId")]
    [Int]$ProcessId = 0,
    # The module name to search for
    [Parameter()]
    [String]$ModuleName,
    # Whether to returned only unsigned modules
    [Parameter()]
    [Switch]$Unsigned
    )

    Begin{
        $script:Modules = @()
        $script:Processes = @()
    }

    Process {
        if ($Process -ne $null)
        {
            $Modules += $Process.Modules 
        }
        elseif (-not [String]::IsNullOrEmpty($ProcessName))
        {
            $Modules += Get-Process -Name $ProcessName | Select-Object -ExpandProperty Modules 
        }
        elseif ($ProcessId -ne 0)
        {
            $Modules += Get-Process -Id $ProcessId | Select-Object -ExpandProperty Modules
        }
        elseif(-not [String]::IsNullOrEmpty($ModuleName))
        {
            $Processes =  Get-Process | Where-Object { ($_.Modules).ModuleName -Contains $ModuleName }
        }
        else 
        {
            $Modules += Get-Process | Select-Object -ExpandProperty Modules
        }
    }

    End {
        if ($Processes.Length -gt 0)
        {
            $Processes
            return
        }

        if (-not [String]::IsNullOrEmpty($ModuleName))
        {
            $Modules = $Modules | Where-Object { $_.ModuleName -eq $ModuleName }
        }

        if ($Unsigned)
        {
            $Modules = $Modules | Where { -not [PoshInternals.AuthenticodeTools]::IsTrusted($_.FileName) }
        }

        $Modules
    }
}