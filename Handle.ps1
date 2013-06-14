<#
.Synopsis
    Gets open system handles.
.DESCRIPTION
   Gets open system handles. This cmdlet can filter by process and handle name. 
.EXAMPLE
   Get-Process Notepad | Get-Handle
.EXAMPLE
   Get-Handle -Name "*myfile.txt"
#>
function Get-Handle
{
    [CmdletBinding()]
    param(
    # A process to return open handles for.
    [Parameter(ValueFromPipeline=$true)]
    [System.Diagnostics.Process]$Process,
    # The name of the handle
    [String]$Name = $null
    )

    Process {
        $Handles = [PoshInternals.HandleUtil]::GetHandles()
        if ($Process -ne $Null)
        {
            $Handles | Where-Object { $_.ProcessId -eq $Process.Id -and $_.Name -match $Name} 
        }
        elseif ($Name -ne $null)
        {
            $Handles |  Where-Object { $_.Name -like $Name} 
        }
        else
        {
            $Handles
        }
    }
}

<#
.Synopsis
    Closes open system handles.
.DESCRIPTION
   Closes open system handles. This cmdlet can cause system instability.
.EXAMPLE
   Get-Process Notepad | Get-Handle | Close-Handle
.EXAMPLE
   Get-Handle -Name "*myfile.txt" | Close-Handle
#>
function Close-Handle
{
    [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='High')]
    param(
    [Parameter(ValueFromPipeline=$true)]
    $Handle
    )

    Process
    {
        if ($PSCmdlet.ShouldProcess($Handle.Name,"Closing a handle can cause system instability. Close handle?"))
        {
            $Handle.Close()
        }
    }
}