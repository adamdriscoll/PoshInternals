function New-MemoryMappedFile
{
	[CmdletBinding()]
	param(
	[Parameter(Mandatory)]
	[String]$Name, 
	[Parameter()]
	[Int64]$Size)

	[System.IO.MemoryMappedFiles.MemoryMappedFile]::CreateNew($Name, $Size);
}

function Open-MemoryMappedFile
{
	param([String]$Name)

	[System.IO.MemoryMappedFiles.MemoryMappedFile]::OpenExisting($Name);
}

function Out-MemoryMappedFile
{
	[CmdletBinding()]
	param(
	[Parameter(Mandatory)]
	[System.IO.MemoryMappedFiles.MemoryMappedFile]$MemoryMappedFile, 
	[Parameter(ValueFromPipeline=$true, Mandatory)]
	[String]$String)

	$Stream = $MemoryMappedFile.CreateViewStream()

	$StreamWriter = New-Object System.IO.StreamWriter -ArgumentList $Stream

	$StreamWriter.Write($String)

	$StreamWriter.Dispose()
	$Stream.Dispose()
}

function Read-MemoryMappedFile
{
	[CmdletBinding()]
	param(
	[Parameter(Mandatory)]
	[System.IO.MemoryMappedFiles.MemoryMappedFile]$MemoryMappedFile)

	$Stream = $MemoryMappedFile.CreateViewStream()

	$StreamReader = New-Object System.IO.StreamReader -ArgumentList $Stream

	$StreamReader.ReadToEnd().Replace("`0", "")
	$StreamReader.Dispose()
	$Stream.Dispose()
}

function Remove-MemoryMappedFile 
{
	[CmdletBinding()]
	param(
	[Parameter(Mandatory)]
	[System.IO.MemoryMappedFiles.MemoryMappedFile]$MemoryMappedFile)

	$MemoryMappedFile.Dispose()
}