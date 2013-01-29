function Get-Handle
{
    [CmdletBinding(DefaultParameterSetName="AllProcesses")]
    param(
    [Parameter(ValueFromPipeline=$true)]
    [System.Diagnostics.Process]$Process,
    $Name=".*"
    )

    Process {
        if ($Process -ne $Null)
        {
            [PoshInternals.HandleUtil]::GetHandles() | Where-Object { $_.ProcessId -eq $Process.Id -and $_.Name -match $Name} 
        }
        else
        {
            [PoshInternals.HandleUtil]::GetHandles() |  Where-Object { $_.Name -like $Name} 
        }
    }
}