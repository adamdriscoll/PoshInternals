if ($PSVersionTable.PSVersion.Major -ge 5)
{
    Write-Verbose -Verbose "Installing PSScriptAnalyzer"
    $PSScriptAnalyzerModuleName = "PSScriptAnalyzer"
    Install-PackageProvider -Name NuGet -Force 
    Install-Module -Name $PSScriptAnalyzerModuleName -Scope CurrentUser -Force 
    $PSScriptAnalyzerModule = get-module -Name $PSScriptAnalyzerModuleName -ListAvailable
    if ($PSScriptAnalyzerModule) {
        # Import the module if it is available
        $PSScriptAnalyzerModule | Import-Module -Force
    }
    else
    {
        # Module could not/would not be installed - so warn user that tests will fail.
        Write-Warning -Message ( @(
            "The 'PSScriptAnalyzer' module is not installed. "
            "The 'PowerShell modules scriptanalyzer' Pester test will fail "
            ) -Join '' )
    }
}
else
{
    Write-Verbose -Verbose "Skipping installation of PSScriptAnalyzer since it requires PSVersion 5.0 or greater. Used PSVersion: $($PSVersion)"
}

$Output = Join-Path $PSScriptRoot TestsResults.xml
$res = Invoke-Pester -Path "$PSScriptRoot\..\Tests" -OutputFormat NUnitXml -OutputFile $Output -PassThru 
(New-Object "System.Net.WebClient").UploadFile("https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)", $Output)
if ($res.FailedCount -gt 0) { 
	throw "$($res.FailedCount) unit tests failed."
}