function Get-Handle
{
    [CmdletBinding()]
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

function Close-Handle
{
    [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='High')]
    param(
    [Parameter(ValueFromPipeline=$true)]
    $Handle
    )

    Process
    {
        $PSCmdlet.ShouldProcess($Handle.Name,"Closing a handle can cause system instability. Close handle?")
        $Handle.Close()
    }
}