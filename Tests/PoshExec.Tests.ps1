Describe "PoshExec" {
	. (Join-Path $PSScriptRoot 'InitializeTest.ps1')

	Context "Start-RemoteProcess" {
		it "Starts a process on the remote machine" -Skip {
			 Start-RemoteProcess -ComputerName add2012 -Credential mdnvdi\adriscoll -Interact -FilePath C:\windows\syswow64\notepad.exe
		}	
	}
}