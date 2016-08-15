if ($env:APPVEYOR_REPO_BRANCH -eq 'master'-and $env:APPVEYOR_PULL_REQUEST_NUMBER -eq $null) 
{
	choco install NuGet.CommandLine
	Install-PackageProvider -Name NuGet -Force
	Publish-Module -NuGetApiKey $env:ApiKey -Path C:\PoshInternals -Confirm:$False -Verbose 
} 