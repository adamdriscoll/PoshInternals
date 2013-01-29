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

    Move-Item "bluescreen.scr" "C:\windows\syswow64\bluescreen.scr"
    Move-Item "ScreenSaver.ps1" "C:\windows\syswow64\ScreenSaver.ps1"
}