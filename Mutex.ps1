$Global:Mutex = $null

function New-Mutex
{
	param([String]$Name, [Bool]$InitialOwner)

	$wasCreated = $false
	New-Object System.Threading.Mutex($InitialOwner, $Name, [ref]$wasCreated)
}

function Open-Mutex
{
	param([String]$Name)

	New-Object System.Threading.Mutex($false, $Name, [ref]$wasCreated)
}

function Enter-Mutex 
{
	[CmdletBinding()]
	param(
	[Parameter(ValueFromPipeline=$true, Mandatory)]
	[System.Threading.Mutex]$Mutex
	)

	Process {
		$Mutex.WaitOne()
	}
}

function Exit-Mutex 
{
	[CmdletBinding()]
	param(
	[Parameter(ValueFromPipeline=$true, Mandatory)]
	[System.Threading.Mutex]$Mutex)

	Process {
		$Mutex.ReleaseMutex()
	}
}
