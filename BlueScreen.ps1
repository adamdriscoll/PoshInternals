<#
.Synopsis
   Installs a blue screen screensaver that mimics the Windows 8 system fault blue screen. 
.DESCRIPTION
   Installs a blue screen screensaver that mimics the Windows 8 system fault blue screen. This cmdlet 
   compiles a custom C# PowerShell SCR file to the system directory that can be used to host any PowerShell
   script. The PowerShell script is responsible for displaying the screen saver.

   You must run this cmdlet from an elevated PowerShell host.
.EXAMPLE
   Install-BlueScreenSaver
#>
function Install-BlueScreenSaver
{
    $CSharp = 
    '
    using System;
    using System.Windows.Forms;
    using System.Management.Automation;
    using System.Management.Automation.Runspaces;

    public class Program 
    {
        static void Main(string[] args)
        {
            using (var runSpace = RunspaceFactory.CreateRunspace())
            {
                runSpace.Open();
                using (var pipeline = runSpace.CreatePipeline("C:\\windows\\System32\\ScreenSaver.ps1"))
                {
                    pipeline.Invoke();
                }
            }
        }
    }

    '

    $tmpFile = [IO.Path]::GetTempFileName() + ".cs"
	$tempDir = [IO.Path]::GetTempPath()

	$ScreenSaverScript = Join-Path (Split-Path $PSCommandPath)  "ScreenSaver.ps1"

	$bsodPath = Join-Path $tempDir "bluescreen.exe"

    Out-File -FilePath $tmpFile -InputObject $CSharp

    Start-Process -FilePath C:\windows\Microsoft.NET\Framework\v4.0.30319\csc.exe -ArgumentList "/out:$bsodPath","/r:`"C:\Program Files (x86)\Reference Assemblies\Microsoft\WindowsPowerShell\3.0\System.Management.Automation.dll`"",$tmpFile -Wait -NoNewWindow 
	
	1..10 | % {
		Start-Sleep -Milliseconds  500
		if (Test-Path $bsodPath)
		{
			break
		}
	}

	if (-not (Test-Path $bsodPath))
	{
		throw new-Object -TypeName System.Exception -ArgumentList "Failed to compile bluescreen.scr"
	}

    Rename-Item $bsodPath "bluescreen.scr"

    $System32 = Join-Path $env:SystemRoot "System32"

    Copy-Item $bsodPath (Join-Path $System32 "bluescreen.scr")
    Copy-Item $ScreenSaverScript (Join-Path $System32 "ScreenSaver.ps1")

    if ($env:PROCESSOR_ARCHITECTURE -eq "AMD64")
    {
        $System32 = Join-Path $env:SystemRoot "SysWow64"
        Copy-Item $bsodPath (Join-Path $System32 "bluescreen.scr")
    }

    Remove-Item $bsodPath
}