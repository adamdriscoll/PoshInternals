function Start-RemoteProcess
{
    [CmdletBinding()]
    param(
    [Parameter()]
    $ComputerName,
    [Parameter(Mandatory)]
    $Credential=(Get-Credential),
    [Parameter()]
    $FilePath,
    [Parameter()]
    [Switch]$Interact
    )

    $Binary = Join-Path ([io.path]::GetTempPath()) "PoshExecSvr.exe"
	$ScriptDirectory = $MyInvocation.MyCommand.Module.ModuleBase

    Add-Type -OutputType ConsoleApplication -OutputAssembly $Binary  -ReferencedAssemblies "System.Data","System.ServiceProcess","System.Xml" -Path (Join-Path $ScriptDirectory "PoshExec.cs")

    New-PSDrive -Name "$ComputerName Admin" -Root "\\$ComputerName\Admin`$"  -Credential $Credential -PSProvider FileSystem | Out-Null 

    Copy-Item $Binary "$ComputerName Admin:\PoshExecSvr.exe" 

    $SCArgs = @("\\$ComputerName","create","PoshExecSvr","binpath= C:\windows\PoshExecSvr.exe")

    Start-Process -FilePath "C:\windows\system32\sc.exe" -ArgumentList $SCArgs -Credential $Credential -NoNewWindow -Wait

    $Service = Get-Service -ComputerName $COmputerName -Name "PoshExecSvr" -ErrorAction SilentlyContinue

    #Sometimes the service isn't quite installed, even if we wait for sc.exe to exit
    if ($Service -eq $null)
    {
        Start-Sleep -Milliseconds 500
        Get-Service -ComputerName $COmputerName -Name "PoshExecSvr" | Start-Service
    }
    else
    {
        $service | Start-Service
    }

    $StartInfo = New-Object PoshExecSvr.StartInfo
    $StartInfo.CommandLine = $FilePath
    $StartInfo.Interact = $Interact

    $Stream = New-Object System.IO.MemoryStream
    $Serializer = New-Object System.Xml.Serialization.XmlSerializer -ArgumentList ([PoshExecSvr.StartInfo])
    $Serializer.Serialize($stream, $startInfo)
    $stream.position = 0

    $sr = New-Object -TypeName System.IO.StreamReader -ArgumentList $stream

    $xml = $sr.ReadToEnd()

    Send-NamedPipeMessage -PipeName "PoshExecSvrPipe" -ComputerName $ComputerName -Message $XML

    Start-Sleep -Seconds 1

    Get-Service -ComputerName $COmputerName -Name "PoshExecSvr" | Stop-Service
    
    Start-Process -FilePath "C:\windows\system32\sc.exe" -ArgumentList "\\$ComputerName","delete","PoshExecSvr" -Credential $Credential -Wait

    Remove-Item "$ComputerName Admin:\PoshExecSvr.exe" 

    Remove-PSDrive -Name "$ComputerName Admin"
}