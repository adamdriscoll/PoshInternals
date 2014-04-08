function Start-RemoteProcess
{
    [CmdletBinding()]
    param(
    [Parameter()]
    $ComputerName,
    [Parameter(Mandatory)]
	[System.Management.Automation.Credential()]
    $Credential=[System.Management.Automation.PSCredential]::Empty,
    [Parameter()]
    $FilePath,
    [Parameter()]
    [Switch]$Interact,
	[Parameter()]
	[Switch]$Cleanup
    )

	$Service = Get-Service -ComputerName $ComputerName -Name "PoshExecSvr" -ErrorAction SilentlyContinue
	$drive = Get-PSDrive -Name "$ComputerName Admin" -ErrorAction SilentlyContinue

	if ($drive -eq $null)
	{
		Write-Verbose "Mapping admin share drive."
		New-PSDrive -Name "$ComputerName Admin" -Root "\\$ComputerName\Admin`$"  -Credential $Credential -PSProvider FileSystem | Out-Null 
	}

	if ($Service -eq $null)
	{
		$Binary = Join-Path ([io.path]::GetTempPath()) "PoshExecSvr.exe"
		$ScriptDirectory = $MyInvocation.MyCommand.Module.ModuleBase

		Write-Verbose "Compiling PoshExecSvr service."
		Add-Type -OutputType ConsoleApplication -OutputAssembly $Binary  -ReferencedAssemblies "System.Data","System.ServiceProcess","System.Xml" -Path (Join-Path $ScriptDirectory "PoshExec.cs")

		Write-Verbose "Copying service to remote machine [$ComputerName]."
		Copy-Item $Binary "$ComputerName Admin:\PoshExecSvr.exe" 

		Write-Verbose "Creating service using service control manager."
		$SCArgs = @("\\$ComputerName","create","PoshExecSvr","binpath= C:\windows\PoshExecSvr.exe")

		Start-Process -FilePath "C:\windows\system32\sc.exe" -ArgumentList $SCArgs -Credential $Credential -Wait -WindowStyle Hidden
	}

	Write-Verbose "Validating service is running."
	$Service = Get-Service -ComputerName $ComputerName -Name "PoshExecSvr" -ErrorAction SilentlyContinue

    #Sometimes the service isn't quite installed, even if we wait for sc.exe to exit
    if ($Service -eq $null -and $Services.Status -ne 'Running')
    {
        Start-Sleep -Milliseconds 500
        Get-Service -ComputerName $ComputerName -Name "PoshExecSvr" | Start-Service
    }
    elseif ($Services.Status -ne 'Running')
    {
		Write-Verbose "Starting service."
        $service | Start-Service
    }

	Add-Type "
	namespace PoshExecSvr
	{
	    [System.Serializable]
		public class StartInfo
		{
			public string CommandLine;
			public bool Interact;
		}
	}
	"

    $StartInfo = New-Object PoshExecSvr.StartInfo
    $StartInfo.CommandLine = $FilePath
    $StartInfo.Interact = $Interact

    $Stream = New-Object System.IO.MemoryStream
    $Serializer = New-Object System.Xml.Serialization.XmlSerializer -ArgumentList ([PoshExecSvr.StartInfo])
    $Serializer.Serialize($stream, $startInfo)
    $stream.position = 0

    $sr = New-Object -TypeName System.IO.StreamReader -ArgumentList $stream

    $xml = $sr.ReadToEnd()

	Write-Verbose "Sending start up info to service."
    Send-NamedPipeMessage -PipeName "PoshExecSvrPipe" -ComputerName $ComputerName -Message $XML

	if ($Cleanup)
	{
		Write-Verbose "Cleaning up service."
		$Service  | Stop-Service 
		Start-Process -FilePath "C:\windows\system32\sc.exe" -ArgumentList "\\$ComputerName","delete","PoshExecSvr" -Credential $Credential -Wait
		Remove-Item "$ComputerName Admin:\PoshExecSvr.exe" 
		Remove-PSDrive -Name "$ComputerName Admin"
	}

    
}