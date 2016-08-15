using System;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.IO.Pipes;
using System.Runtime.ConstrainedExecution;
using System.Security.AccessControl;
using System.Security.Cryptography;
using System.Security.Principal;
using System.ServiceProcess;
using System.Runtime.InteropServices;
using System.Threading;
using System.Xml.Serialization;

namespace PoshExecSvr
{
    public class Service1 : ServiceBase
    {
        private ManualResetEvent _started = new ManualResetEvent(false);
        private System.ComponentModel.IContainer components;
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
            ServiceName = "PoshExecSvc";
        }

        public Service1()
        {
            InitializeComponent();
        }

        public void Start()
        {
            Listen("PoshExecSvrPipe");
            _started.WaitOne();
        }


        protected override void OnStart(string[] args)
        {
            Start();
        }

        string _pipeName;
        private PipeSecurity _security;

        public void Listen(string pipeName)
        {
            try
            {
                _security = new PipeSecurity();

                // Allow Everyone read and write access to the pipe. 
                _security.SetAccessRule(new PipeAccessRule("Authenticated Users", PipeAccessRights.ReadWrite, AccessControlType.Allow));

                // Allow the Administrators group full access to the pipe. 
                _security.SetAccessRule(new PipeAccessRule("Administrators", PipeAccessRights.FullControl, AccessControlType.Allow)); 

                // Set to class level var so we can re-use in the async callback method
                _pipeName = pipeName;
                // Create the new async pipe 
                var pipeServer = new NamedPipeServerStream(_pipeName,
                   PipeDirection.In, 1, PipeTransmissionMode.Message, PipeOptions.Asynchronous, 1024, 1024, _security);

                // Wait for a connection
                pipeServer.BeginWaitForConnection(WaitForConnectionCallBack, pipeServer);

                _started.Set();
            }
            catch (Exception oEx)
            {
                Debug.WriteLine(oEx.Message);
            }
        }


        private void WaitForConnectionCallBack(IAsyncResult iar)
        {
            try
            {
                // Get the pipe
                var pipeServer = (NamedPipeServerStream)iar.AsyncState;
                // End waiting for the connection
                pipeServer.EndWaitForConnection(iar);

                var bRequest = new byte[1024];
                do
                {
                    int cbRequest = bRequest.Length;
                    pipeServer.Read(bRequest, 0, cbRequest);
                }
                while (!pipeServer.IsMessageComplete);

                var serializer = new XmlSerializer(typeof(StartInfo));
                var startInfo = (StartInfo)serializer.Deserialize(new MemoryStream(bRequest));

                NativeMethods.EnableSecurityRights("SeTcbPrivilege", true);
                NativeMethods.EnableSecurityRights("SeAssignPrimaryTokenPrivilege", true);
                NativeMethods.EnableSecurityRights("SeIncreaseQuotaPrivilege", true);

                pipeServer.RunAsClient(() =>
                {
                    PROCESS_INFORMATION procInfo;
                    var startupInfo = new STARTUPINFO();

                    int size = Marshal.SizeOf(startupInfo);
                    startupInfo.cb = size;

                    if (startInfo.Interact)
                    {
                        //TODO: Find right session ID and call SetTokenInformation to set it to the user token

                        startupInfo.dwFlags = 0x00000001; //#define STARTF_USESHOWWINDOW       
                        startupInfo.wShowWindow = 5; //#define SW_SHOW             
                        startupInfo.lpDesktop = "WinSta0\\Default";
                    }

                    if (!CreateProcessAsUser(WindowsIdentity.GetCurrent().Token, null, startInfo.CommandLine, IntPtr.Zero, IntPtr.Zero, false, 0, IntPtr.Zero, null, ref startupInfo, out procInfo))
                    {
                        Debug.WriteLine(String.Format("{0}", Marshal.GetLastWin32Error()));
                    }
                });
 
                // Kill original sever and create new wait server
                pipeServer.Close();
                pipeServer = new NamedPipeServerStream(_pipeName, PipeDirection.In,
                   1, PipeTransmissionMode.Message, PipeOptions.Asynchronous, 1024, 1024, _security);

                // Recursively wait for the connection again and again....
                pipeServer.BeginWaitForConnection(
                   WaitForConnectionCallBack, pipeServer);
            }
            catch (Exception ex)
            {
                Debug.WriteLine(ex.Message);
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
        static extern bool WTSQueryUserToken(UInt32 sessionId, out IntPtr handle);

        [DllImport("Kernel32.dll", SetLastError = true)]
        static extern UInt32 WTSGetActiveConsoleSessionId();
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
            var service = new Service1();

            if (!Environment.UserInteractive)
            {
                var servicesToRun = new ServiceBase[] { service };
                ServiceBase.Run(servicesToRun);
                return;
            }

            service.Start();
            Console.ReadLine();
        }
    }


        [Flags]
        internal enum TokenAccessLevels
        {
            AssignPrimary = 0x00000001,
            Duplicate = 0x00000002,
            Impersonate = 0x00000004,
            Query = 0x00000008,
            QuerySource = 0x00000010,
            AdjustPrivileges = 0x00000020,
            AdjustGroups = 0x00000040,
            AdjustDefault = 0x00000080,
            AdjustSessionId = 0x00000100,

            Read = 0x00020000 | Query,

            Write = 0x00020000 | AdjustPrivileges | AdjustGroups | AdjustDefault,

            AllAccess = 0x000F0000 |
                AssignPrimary |
                Duplicate |
                Impersonate |
                Query |
                QuerySource |
                AdjustPrivileges |
                AdjustGroups |
                AdjustDefault |
                AdjustSessionId,

            MaximumAllowed = 0x02000000
        }

        internal enum SecurityImpersonationLevel
        {
            Anonymous = 0,
            Identification = 1,
            Impersonation = 2,
            Delegation = 3,
        }

        internal enum TokenType
        {
            Primary = 1,
            Impersonation = 2,
        }

        internal sealed class NativeMethods
        {
            public static void EnableSecurityRights(string desiredAccess, bool on)
            {

                IntPtr token = IntPtr.Zero;
                if (!OpenProcessToken(GetCurrentProcess(), TokenAccessLevels.AdjustPrivileges | TokenAccessLevels.Query,
                    ref token))
                {
                    return;
                }
                LUID luid = new LUID();
                if (!LookupPrivilegeValue(null, desiredAccess, ref luid))
                {
                    CloseHandle(token);
                    return;
                }

                TOKEN_PRIVILEGE tp = new TOKEN_PRIVILEGE();
                tp.PrivilegeCount = 1;
                tp.Privilege = new LUID_AND_ATTRIBUTES();
                tp.Privilege.Attributes = on ? SE_PRIVILEGE_ENABLED : SE_PRIVILEGE_DISABLED;
                tp.Privilege.Luid = luid;

                int cbTp = Marshal.SizeOf(tp);

                if (!AdjustTokenPrivileges(token, false, ref tp, (uint) cbTp, IntPtr.Zero, IntPtr.Zero))
                {
                    Debug.WriteLine(new Win32Exception().Message);
                }
                CloseHandle(token);
            }

            internal const uint SE_PRIVILEGE_DISABLED = 0x00000000;
            internal const uint SE_PRIVILEGE_ENABLED = 0x00000002;

            [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
            internal struct LUID
            {
                internal uint LowPart;
                internal uint HighPart;
            }

            [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
            internal struct LUID_AND_ATTRIBUTES
            {
                internal LUID Luid;
                internal uint Attributes;
            }

            [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
            internal struct TOKEN_PRIVILEGE
            {
                internal uint PrivilegeCount;
                internal LUID_AND_ATTRIBUTES Privilege;
            }

            internal const string ADVAPI32 = "advapi32.dll";
            internal const string KERNEL32 = "kernel32.dll";

            internal const int ERROR_SUCCESS = 0x0;
            internal const int ERROR_ACCESS_DENIED = 0x5;
            internal const int ERROR_NOT_ENOUGH_MEMORY = 0x8;
            internal const int ERROR_NO_TOKEN = 0x3f0;
            internal const int ERROR_NOT_ALL_ASSIGNED = 0x514;
            internal const int ERROR_NO_SUCH_PRIVILEGE = 0x521;
            internal const int ERROR_CANT_OPEN_ANONYMOUS = 0x543;

            [DllImport(
                 KERNEL32,
                 SetLastError = true)]
            [ReliabilityContract(Consistency.WillNotCorruptState, Cer.MayFail)]
            internal static extern bool CloseHandle(IntPtr handle);

            [DllImport(
                 ADVAPI32,
                 CharSet = CharSet.Unicode,
                 SetLastError = true)]
            [ReliabilityContract(Consistency.WillNotCorruptState, Cer.MayFail)]
            internal static extern bool AdjustTokenPrivileges(
                [In]     IntPtr TokenHandle,
                [In]     bool DisableAllPrivileges,
                [In]     ref TOKEN_PRIVILEGE NewState,
                [In]     uint BufferLength,
                [In, Out] IntPtr PreviousState,
                [In, Out] IntPtr ReturnLength);

            [DllImport(
                 ADVAPI32,
                 CharSet = CharSet.Auto,
                 SetLastError = true)]
            [ReliabilityContract(Consistency.WillNotCorruptState, Cer.MayFail)]
            internal static extern
            bool RevertToSelf();

            [DllImport(
                 ADVAPI32,
                 EntryPoint = "LookupPrivilegeValueW",
                 CharSet = CharSet.Auto,
                 SetLastError = true)]
            [ReliabilityContract(Consistency.WillNotCorruptState, Cer.MayFail)]
            internal static extern
            bool LookupPrivilegeValue(
                [In]     string lpSystemName,
                [In]     string lpName,
                [In, Out] ref LUID Luid);

            [DllImport(
                 KERNEL32,
                 CharSet = CharSet.Auto,
                 SetLastError = true)]
            [ReliabilityContract(Consistency.WillNotCorruptState, Cer.MayFail)]
            internal static extern
            IntPtr GetCurrentProcess();

            [DllImport(
                 KERNEL32,
                 CharSet = CharSet.Auto,
                 SetLastError = true)]
            [ReliabilityContract(Consistency.WillNotCorruptState, Cer.MayFail)]
            internal static extern
                IntPtr GetCurrentThread();

            [DllImport(
                 ADVAPI32,
                 CharSet = CharSet.Unicode,
                 SetLastError = true)]
            [ReliabilityContract(Consistency.WillNotCorruptState, Cer.MayFail)]
            internal static extern
            bool OpenProcessToken(
                [In]     IntPtr ProcessToken,
                [In]     TokenAccessLevels DesiredAccess,
                [In, Out] ref IntPtr TokenHandle);

            [DllImport
                 (ADVAPI32,
                 CharSet = CharSet.Unicode,
                 SetLastError = true)]
            [ReliabilityContract(Consistency.WillNotCorruptState, Cer.MayFail)]
            internal static extern
            bool OpenThreadToken(
                [In]     IntPtr ThreadToken,
                [In]     TokenAccessLevels DesiredAccess,
                [In]     bool OpenAsSelf,
                [In, Out] ref IntPtr TokenHandle);

            [DllImport
                (ADVAPI32,
                 CharSet = CharSet.Unicode,
                 SetLastError = true)]
            [ReliabilityContract(Consistency.WillNotCorruptState, Cer.MayFail)]
            internal static extern
            bool DuplicateTokenEx(
                [In]    IntPtr ExistingToken,
                [In]    TokenAccessLevels DesiredAccess,
                [In]    IntPtr TokenAttributes,
                [In]    SecurityImpersonationLevel ImpersonationLevel,
                [In]    TokenType TokenType,
                [In, Out] ref IntPtr NewToken);

            [DllImport
                 (ADVAPI32,
                 CharSet = CharSet.Unicode,
                 SetLastError = true)]
            [ReliabilityContract(Consistency.WillNotCorruptState, Cer.MayFail)]
            internal static extern
            bool SetThreadToken(
                [In]    IntPtr Thread,
                [In]    IntPtr Token);

        }
}