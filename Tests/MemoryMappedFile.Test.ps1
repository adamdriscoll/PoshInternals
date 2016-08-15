TestFixture "MemoryMappedFileTest" {
	TestSetup {
		$Parent = Split-Path (Split-Path $PSCommandPath -Parent)
		Import-Module (Join-Path $Parent "PoshInternals.psd1") -Force
	}

	TestCase "ReadWriteFromMemoryMappedFile" {
		$MemoryMappedFile = New-MemoryMappedFile -Name "TestFile" -Size 1kb

		"This is a test" | Out-MemoryMappedFile -MemoryMappedFile $MemoryMappedFile

		$OtherMemoryMappedFile = Open-MemoryMappedFile -Name "TestFile"

		$TestData = Read-MemoryMappedFile -MemoryMappedFile $OtherMemoryMappedFile

		Remove-MemoryMappedFile -MemoryMappedFile $MemoryMappedFile
		Remove-MemoryMappedFile -MemoryMappedFile $OtherMemoryMappedFile

		$TestData | Should be "This is a test"
	}
}