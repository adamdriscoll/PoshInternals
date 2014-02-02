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
using System.Runtime.InteropServices;
using System.Xml.Serialization;

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
            this.ServiceName = "PoshExecSvc";
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
            pipeSecurity.SetAccessRule(new PipeAccessRule("Authenticated Users", PipeAccessRights.ReadWrite, AccessControlType.Allow));

            // Allow the Administrators group full access to the pipe. 
            pipeSecurity.SetAccessRule(new PipeAccessRule("Administrators", PipeAccessRights.FullControl, AccessControlType.Allow)); 

            using (var stream = new NamedPipeServerStream( 
                                                            "PoshExecSvrPipe",              // The unique pipe name. 
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

                    byte[] bRequest = new byte[1024];
                    do
                    {
                               
                        int cbRequest = bRequest.Length;
                        stream.Read(bRequest, 0, cbRequest);
                        // message = Encoding.Unicode.GetString(bRequest).TrimEnd('\0');
                    }
                    while (!stream.IsMessageComplete);

                    XmlSerializer serializer = new XmlSerializer(typeof(StartInfo));
                    var startInfo = (StartInfo)serializer.Deserialize(new MemoryStream(bRequest));

                    stream.RunAsClient(() =>
                        {
                            PROCESS_INFORMATION procInfo;
                            STARTUPINFO startupInfo = new STARTUPINFO();

                            int size = Marshal.SizeOf(startupInfo);
                            startupInfo.cb = size;

                            if (startInfo.Interact)
                            {
                                startupInfo.lpDesktop = "winsta0\\desktop";
                            }

                            IntPtr handle;
                            WTSQueryUserToken(WTSGetActiveConsoleSessionId(), out handle);

                            if (!CreateProcessAsUser(handle, null, startInfo.CommandLine, IntPtr.Zero, IntPtr.Zero, false, 0, IntPtr.Zero, null, ref startupInfo, out procInfo))
                            {
                                File.WriteAllText("C:\\log.txt", String.Format("{0}", Marshal.GetLastWin32Error()));
                            }
                        });

                    stream.WaitForPipeDrain();
                    stream.Disconnect();                     
                }
            }
        }

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool CreateProcess(string lpApplicationName,
            string lpCommandLine, IntPtr lpProcessAttributes, 
            IntPtr lpThreadAttributes, bool bInheritHandles, 
            uint dwCreationFlags, IntPtr lpEnvironment, string lpCurrentDirectory,
            [In] ref STARTUPINFO lpStartupInfo, 
            out PROCESS_INFORMATION lpProcessInformation);

        [DllImport("advapi32.dll", SetLastError=true, CharSet=CharSet.Auto)]
        static extern bool CreateProcessAsUser(
            IntPtr hToken,
            string lpApplicationName,
            string lpCommandLine,
            IntPtr lpProcessAttributes,
            IntPtr lpThreadAttributes,
            bool bInheritHandles,
            uint dwCreationFlags,
            IntPtr lpEnvironment,
            string lpCurrentDirectory,
            ref STARTUPINFO lpStartupInfo,
            out PROCESS_INFORMATION lpProcessInformation);     

                
        [DllImport("Wtsapi32.dll", SetLastError = true)]
        static extern bool WTSQueryUserToken(long sessionId, out IntPtr handle);

        [DllImport("Wtsapi32.dll", SetLastError = true)]
        static extern long WTSGetActiveConsoleSessionId();
    }
            
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    struct STARTUPINFO
    {
        public Int32 cb;
        public string lpReserved;
        public string lpDesktop;
        public string lpTitle;
        public Int32 dwX;
        public Int32 dwY;
        public Int32 dwXSize;
        public Int32 dwYSize;
        public Int32 dwXCountChars;
        public Int32 dwYCountChars;
        public Int32 dwFillAttribute;
        public Int32 dwFlags;
        public Int16 wShowWindow;
        public Int16 cbReserved2;
        public IntPtr lpReserved2;
        public IntPtr hStdInput;
        public IntPtr hStdOutput;
        public IntPtr hStdError;
    }

    [StructLayout(LayoutKind.Sequential)]
    internal struct PROCESS_INFORMATION 
    {
        public IntPtr hProcess;
        public IntPtr hThread;
        public int dwProcessId;
        public int dwThreadId;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct SECURITY_ATTRIBUTES
    {
        public int nLength;
        public IntPtr lpSecurityDescriptor;
        public int bInheritHandle;
    }

    [Serializable]
    public class StartInfo
    {
        public string CommandLine;
        public bool Interact;
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