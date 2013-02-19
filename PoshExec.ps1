function Start-RemoteProcess
{
    [CmdletBinding()]
    param(
    [Parameter()]
    $ComputerName,
    [Parameter(Mandatory)]
    $Credential=(Get-Credential),
    [Parameter()]
    $FilePath
    )



    $Binary = Join-Path ([io.path]::GetTempPath()) "PoshExecSvr.exe"
    Add-Type -OutputType ConsoleApplication -OutputAssembly $Binary  -ReferencedAssemblies "System.Data","System.ServiceProcess" -TypeDefinition "
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.IO;
using System.IO.Pipes;
using System.Linq;
using System.Security.AccessControl;
using System.ServiceProcess;
using System.Text;
using System.Threading.Tasks;

namespace PoshExecSvr
{
    public class Service1 : ServiceBase
    {
        private System.ComponentModel.IContainer components = null;
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }
        private void InitializeComponent()
        {
            components = new System.ComponentModel.Container();
            this.ServiceName = `"PoshExecSvc`";
        }

        private bool _stopping;
        private Task _taskHandle;

        public Service1()
        {
            InitializeComponent();
        }

        public void Start()
        {
            _stopping = false;

            _taskHandle = Task.Run((Action)MessageLoop);
        }


        protected override void OnStart(string[] args)
        {
            Start();
        }

        protected override void OnStop()
        {
            _stopping = true;
        }

        private void MessageLoop()
        {
            PipeSecurity pipeSecurity = new PipeSecurity();

            // Allow Everyone read and write access to the pipe. 
            pipeSecurity.SetAccessRule(new PipeAccessRule(`"Authenticated Users`", PipeAccessRights.ReadWrite, AccessControlType.Allow));

            // Allow the Administrators group full access to the pipe. 
            pipeSecurity.SetAccessRule(new PipeAccessRule(`"Administrators`", PipeAccessRights.FullControl, AccessControlType.Allow)); 

            using (var stream = new NamedPipeServerStream( 
                                                            `"PoshExecSvrPipe`",              // The unique pipe name. 
                                                            PipeDirection.InOut,            // The pipe is duplex 
                                                            NamedPipeServerStream.MaxAllowedServerInstances, 
                                                            PipeTransmissionMode.Message,   // Message-based communication 
                                                            PipeOptions.None,               // No additional parameters 
                                                            1024,            // Input buffer size 
                                                            1024,            // Output buffer size 
                                                            pipeSecurity,                   // Pipe security attributes 
                                                            HandleInheritability.None       // Not inheritable 
                                                            ))
            {
                while (!_stopping)
                {
                    stream.WaitForConnection();

                    string message;
                    do
                    {
                        byte[] bRequest = new byte[1024];
                        int cbRequest = bRequest.Length;
                        stream.Read(bRequest, 0, cbRequest);
                        message = Encoding.Unicode.GetString(bRequest).TrimEnd('\0');
                    }
                    while (!stream.IsMessageComplete);

                    stream.RunAsClient(() =>
                        {
                            var process = Process.Start(message);
                        });

                    stream.WaitForPipeDrain();
                    stream.Disconnect();                     
                }
                
            }
        }
    }

    static class Program
    {
        /// <summary>
        /// The main entry point for the application.
        /// </summary>
        static void Main()
        {
            ServiceBase[] ServicesToRun;
            ServicesToRun = new ServiceBase[] 
            { 
                new Service1() 
            };
            ServiceBase.Run(ServicesToRun);    
        }
    }

}
    " 

    New-PSDrive -Name "$ComputerName Admin" -Root "\\$ComputerName\Admin`$"  -Credential $Credential -PSProvider FileSystem | Out-Null

    Copy-Item $Binary "$ComputerName Admin:\PoshExecSvr.exe" 

    Start-Process -FilePath "C:\windows\system32\sc.exe" -ArgumentList "\\$ComputerName","create","PoshExecSvr","binpath= C:\windows\PoshExecSvr.exe" -Credential $Credential

    Get-Service -ComputerName $COmputerName -Name "PoshExecSvr" | Start-Service

    Send-NamedPipeMessage -PipeName "PoshExecSvrPipe" -ComputerName $ComputerName -Message $FilePath

    Get-Service -ComputerName $COmputerName -Name "PoshExecSvr" | Stop-Service

    Start-Process -FilePath "C:\windows\system32\sc.exe" -ArgumentList "\\$ComputerName","delete","PoshExecSvr" -Credential $Credential

    Remove-Item "$ComputerName Admin:\PoshExecSvr.exe" 

    Remove-PSDrive -Name "$ComputerName Admin"
}