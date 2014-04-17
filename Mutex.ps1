$Global:Mutex

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
	[Parameter(ValueFromPipeline=$true, Mandatory, ParmeterSetName='Mutex')]
	[System.Threading.Mutex]$Mutex,
	[Parameter(ValueFromPipeline=$true, Mandatory, ParmeterSetName='Name')]
	[System.Threading.Mutex]$Name
	)

	Process {
		if ($PSCmdlet.ParameterSetName -eq 'Mutex')
		{
			$Mutex.WaitOne()
		}
		elseif ($PSCmdlet.ParameterSetName -eq 'Name')
		{

		}


		
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
