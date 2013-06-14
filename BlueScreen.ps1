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
                using (var pipeline = runSpace.CreatePipeline("C:\\windows\\syswow64\\ScreenSaver.ps1"))
                {
                    pipeline.Invoke();
                }
            }
        }
    }

    '

    $tmpFile = [IO.Path]::GetTempFileName() + ".cs"

    Out-File -FilePath $tmpFile -InputObject $CSharp

    Start-Process -FilePath C:\windows\Microsoft.NET\Framework\v4.0.30319\csc.exe -ArgumentList "/out:bluescreen.exe","/r:`"C:\Windows\Microsoft.NET\assembly\GAC_MSIL\System.Management.Automation\v4.0_3.0.0.0__31bf3856ad364e35\System.Management.Automation.dll`"",$tmpFile -Wait

    Rename-Item "bluescreen.exe" "bluescreen.scr"

    $System32 = Join-Path $env:SystemRoot "System32"

    Copy-Item "bluescreen.scr" (Join-Path $System32 "bluescreen.scr")
    Copy-Item "ScreenSaver.ps1" (Join-Path $System32 "ScreenSaver.ps1")

    if ($env:PROCESSOR_ARCHITECTURE -eq "AMD64")
    {
        $System32 = Join-Path $env:SystemRoot "SysWow64"

        Copy-Item "bluescreen.scr" (Join-Path $System32 "bluescreen.scr")
        Copy-Item "ScreenSaver.ps1" (Join-Path $System32 "ScreenSaver.ps1")
    }

    Remove-Item "bluescreen.scr"
}