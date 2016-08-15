Describe "MemoryMappFile" {
	. (Join-Path $PSScriptRoot 'InitializeTest.ps1')

	Context "ReadWriteFromMemoryMappedFile" {
		$MemoryMappedFile = New-MemoryMappedFile -Name "TestFile" -Size 1kb

		"This is a test" | Out-MemoryMappedFile -MemoryMappedFile $MemoryMappedFile

		$OtherMemoryMappedFile = Open-MemoryMappedFile -Name "TestFile"

		$TestData = Read-MemoryMappedFile -MemoryMappedFile $OtherMemoryMappedFile

		Remove-MemoryMappedFile -MemoryMappedFile $MemoryMappedFile
		Remove-MemoryMappedFile -MemoryMappedFile $OtherMemoryMappedFile

		It "should contain the correct data" {
			$TestData | Should be "This is a test"
		}
		
	}
}