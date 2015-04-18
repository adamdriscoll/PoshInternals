
 function Get-LogonSession
 {
	[CmdletBinding()]
	param(
		[Parameter(ValueFromPipeline=$true)]
		[String[]]$ComputerName = 'localhost')

		Process {
			$server = [PoshInternals.Wtsapi32]::WTSOpenServer($ComputerName )
			if ($server -eq [IntPtr]::Zero)
			{
				throw new-Object  System.ComponentModel.Win32Exception
			}

			$SessionInfoPtr = [IntPtr]::Zero
			$sessionCount = 0
			$retVal = [PoshInternals.Wtsapi32]::WTSEnumerateSessions($server, 0, 1, [ref] $SessionInfoPtr, [ref] $sessionCount)
			
			if ($retVal)
			{
				$dataSize = Get-Size -Type ([PoshInternals.WTS_SESSION_INFO])
				$currentSession = [long]$SessionInfoPtr
				$bytes = 0

				for ($i = 0; $i -lt $sessionCount; $i++)
				{
					$si = ConvertTo-Object ([System.IntPtr]$currentSession) ([PoshInternals.WTS_SESSION_INFO])
					$currentSession += $dataSize;

					$userPtr = [IntPtr]::Zero
					$domainPtr = [IntPtr]::Zero

					if (! [PoshInternals.Wtsapi32]::WTSQuerySessionInformation($server, $si.SessionID, [PoshInternals.WTS_INFO_CLASS]::WTSUserName, [ref] $userPtr, [ref] $bytes) )
					{
						throw new-Object  System.ComponentModel.Win32Exception
					}
					
					if (! [PoshInternals.Wtsapi32]::WTSQuerySessionInformation($server, $si.SessionID, [PoshInternals.WTS_INFO_CLASS]::WTSDomainName, [ref] $domainPtr, [ref] $bytes))
					{
						throw new-Object  System.ComponentModel.Win32Exception
					}

					[PSCustomObject]@{
						Domain = (ConvertTo-String $domainPtr -Ansi);
						UserName = (ConvertTo-String $userPtr -Ansi);
					}

					[PoshInternals.Wtsapi32]::WTSFreeMemory($userPtr) | Out-Null
					[PoshInternals.Wtsapi32]::WTSFreeMemory($domainPtr) | Out-Null
				}

				[PoshInternals.Wtsapi32]::WTSFreeMemory($SessionInfoPtr) | Out-Null
				[PoshInternals.Wtsapi32]::WTSCloseServer($Server) | Out-Null
			}
			else
			{
				throw new-Object  System.ComponentModel.Win32Exception
			}
		}
 }
