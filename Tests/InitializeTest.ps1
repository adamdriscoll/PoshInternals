if ($ENV:APPVEYOR -ne 'true')
{
	$ENV:APPVEYOR_BUILD_VERSION = '99.99'
	. (Join-Path $PSScriptRoot '..\Build\NewManifest.ps1')
}
		
Import-Module (Join-Path $PSScriptRoot "..\PoshInternals.psd1") -Force -Global -ErrorAction Stop