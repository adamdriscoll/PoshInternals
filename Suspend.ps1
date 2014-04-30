function Suspend-Process
{
	[CmdletBinding()]
	param(
	[Parameter(ValueFromPipeline=$true)]
	[System.Diagnostics.Process]$Process)

	Process {
		$Process.Threads | ForEach-Object {
			$pOpenThread = [PoshInternals.Kernel32]::OpenThread([PoshInternals.ThreadAccess]::SUSPEND_RESUME, $false, [System.UInt32]$_.Id);

			if ($pOpenThread -eq [IntPtr]::Zero)
			{
				continue
			}

			[PoshInternals.Kernel32]::SuspendThread($pOpenThread) | Out-Null 
		}
	}
}

function Resume-Process
{
	[CmdletBinding()]
	param(
	[Parameter(ValueFromPipeline=$true)]
	[System.Diagnostics.Process]$Process)

	Process {
		$Process.Threads | ForEach-Object {
			$pOpenThread = [PoshInternals.Kernel32]::OpenThread([PoshInternals.ThreadAccess]::SUSPEND_RESUME, $false, [System.UInt32]$_.Id);

			if ($pOpenThread -eq [IntPtr]::Zero)
			{
				continue
			}

			[PoshInternals.Kernel32]::ResumeThread($pOpenThread)  | Out-Null 
		}
	}
}