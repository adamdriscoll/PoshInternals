function Get-Dll
{
    [CmdletBinding()]
    param(
    [Parameter(ValueFromPipeline=$true)]
    [String]$ProcessName = "",
    [Parameter(ValueFromPipeline=$true)]
    [Int]$ProcessId = 0,
    [Parameter()]
    [String]$ModuleName,
    [Parameter()]
    [Switch]$Unsigned
    )

    Begin{
        $script:Modules = @()
        $script:Processes = @()
    }

    Process {
        if (-not [String]::IsNullOrEmpty($ProcessName))
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