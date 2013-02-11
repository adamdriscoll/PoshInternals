#Sunny Chakraborty (@sunnyc7)(sunnyc7@gmail.com)
#License: MIT-3 > Use as you please + Don't Sue Me. 
#FileMon tricks

Function Get-ProcessLaunches([string[]]$computer) {

BEGIN {
Function Write-Log([string]$info){            
if($loginitialized -eq $false){            
    $FileHeader > $logfile            
    $script:loginitialized = $True            
    }            
    $info >> $logfile            
} # End of Function Write-Log

#Logfile Path
$script:logfile = "c:\scripts\procmonlog.txt"            
}

PROCESS {
#WQL on InstanceCreationEvent
$query =  "Select * FROM __InstanceCreationEvent WITHIN 2 WHERE TargetInstance ISA 'Win32_Process'"

#Delete Previously Loaded Jobs
Get-Job -Name RemoteProcMon | Remove-Job | Out-Null

#WMI Event Monitor
Register-WmiEvent <#-ComputerName $computer#> -Query $query -SourceIdentifier RemoteProcMon -Action{
    $Global:RemoteProcMon=$event 
    Write-Host "$((get-date).ToLongTimeString()), $($Event.SourceEventArgs.NewEvent.TargetInstance.Name) started on $($Event.SourceEventArgs.NewEvent.TargetInstance.PSComputerName) with PID=$($Event.SourceEventArgs.NewEvent.TargetInstance.ProcessID) and ParentPID=$($Event.SourceEventArgs.NewEvent.TargetInstance.ParentProcessId)"
    # You can change Write-Host to Write-Log, and edit the log-path above to have the events logged to a file.
    
    }
    } # End Process
} # End of Function.

<# COMMENTS / Annotations.

02.11.2013 -Sunny:

I was going with a logging to a file, instead of building up Objects in memory to be processed by something in pipeline.
IMHO File / Database Logging is more appropriate in this situation.
I kept it at Write-host so that you can see the magic. You can use -Computername parameter in Register-WMI to run this against multiple computers 
and have all of them log to one common path like c:\log\something

** Logging and other functions can be vastly improved.

This is really really rough draft.

** Running this program wont in production wont harm your computer with Write-Host intact. 
If you use logging funtionality, it will log stuff. **

#>