TestFixture "PoshExec" {
	TestSetup {
		$Parent = Split-Path (Split-Path $PSCommandPath -Parent)
		Import-Module (Join-Path $Parent "PoshInternals.psd1") -Force
	}

	TestCase "ConnectToServer" {
		Start-RemoteProcess -ComputerName add2012 -Credential mdnvdi\adriscoll -Interact -FilePath C:\windows\syswow64\notepad.exe
	}
}