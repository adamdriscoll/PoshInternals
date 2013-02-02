# Dont run Set-WorkingSet on sqlservr.exe, store.exe and similar processes
# Todo: Check process name and filter
# Example - get-process notepad | Set-WorkingSetToMin 
Function Set-WorkingSetToMin {
    [CmdletBinding()]
    param(
    [Parameter(ValueFromPipeline=$True, Mandatory=$true)]
    [System.Diagnostics.Process] $Process
    )

if ($Process -ne $Null)
{
    $handle = $Process.Handle
    $from = ($process.WorkingSet/1MB) 
    $to = [PoshInternals.Kernel32]::SetProcessWorkingSetSize($handle,-1,-1) | Out-Null
    Write-Output "Trimming Working Set Values from: $from"
    
} #End of If
} # End of Function
