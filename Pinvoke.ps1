Add-Type -TypeDefinition '
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.ComponentModel;
using System.Runtime.ConstrainedExecution;
using System.Runtime.InteropServices;

namespace PoshInternals {
public static class AuthenticodeTools
{
    [DllImport("Wintrust.dll", PreserveSig = true, SetLastError = false)]
    private static extern uint WinVerifyTrust(IntPtr hWnd, IntPtr pgActionID, IntPtr pWinTrustData);
    private static uint WinVerifyTrust(string fileName)
    {

        Guid wintrust_action_generic_verify_v2 = new Guid("{00AAC56B-CD44-11d0-8CC2-00C04FC295EE}");
        uint result=0;
        using (WINTRUST_FILE_INFO fileInfo = new WINTRUST_FILE_INFO(fileName,
                                                                    Guid.Empty))
        using (UnmanagedPointer guidPtr = new UnmanagedPointer(Marshal.AllocHGlobal(Marshal.SizeOf(typeof (Guid))),
                                                               AllocMethod.HGlobal))
        using (UnmanagedPointer wvtDataPtr = new UnmanagedPointer(Marshal.AllocHGlobal(Marshal.SizeOf(typeof (WINTRUST_DATA))),
                                                                  AllocMethod.HGlobal))
        {
            WINTRUST_DATA data = new WINTRUST_DATA(fileInfo);
            IntPtr pGuid = guidPtr;
            IntPtr pData = wvtDataPtr;
            Marshal.StructureToPtr(wintrust_action_generic_verify_v2,
                                   pGuid,
                                   true);
            Marshal.StructureToPtr(data,
                                   pData,
                                   true);
            result = WinVerifyTrust(IntPtr.Zero,
                                    pGuid,
                                    pData);

        }
        return result;

    }
    public static bool IsTrusted(string fileName)
    {
        return WinVerifyTrust(fileName) == 0;
    }


}

internal struct WINTRUST_FILE_INFO : IDisposable
{

    public WINTRUST_FILE_INFO(string fileName, Guid subject)
    {

        cbStruct = (uint)Marshal.SizeOf(typeof(WINTRUST_FILE_INFO));

        pcwszFilePath = fileName;



        if (subject != Guid.Empty)
        {

            pgKnownSubject = Marshal.AllocHGlobal(Marshal.SizeOf(typeof(Guid)));

            Marshal.StructureToPtr(subject, pgKnownSubject, true);

        }

        else
        {

            pgKnownSubject = IntPtr.Zero;

        }

        hFile = IntPtr.Zero;

    }

    public uint cbStruct;

    [MarshalAs(UnmanagedType.LPTStr)]

    public string pcwszFilePath;

    public IntPtr hFile;

    public IntPtr pgKnownSubject;



    #region IDisposable Members



    public void Dispose()
    {

        Dispose(true);

    }



    private void Dispose(bool disposing)
    {

        if (pgKnownSubject != IntPtr.Zero)
        {

            Marshal.DestroyStructure(this.pgKnownSubject, typeof(Guid));

            Marshal.FreeHGlobal(this.pgKnownSubject);

        }

    }



    #endregion

}

enum AllocMethod
{
    HGlobal,
    CoTaskMem
};
enum UnionChoice
{
    File = 1,
    Catalog,
    Blob,
    Signer,
    Cert
};
enum UiChoice
{
    All = 1,
    NoUI,
    NoBad,
    NoGood
};
enum RevocationCheckFlags
{
    None = 0,
    WholeChain
};
enum StateAction
{
    Ignore = 0,
    Verify,
    Close,
    AutoCache,
    AutoCacheFlush
};
enum TrustProviderFlags
{
    UseIE4Trust = 1,
    NoIE4Chain = 2,
    NoPolicyUsage = 4,
    RevocationCheckNone = 16,
    RevocationCheckEndCert = 32,
    RevocationCheckChain = 64,
    RecovationCheckChainExcludeRoot = 128,
    Safer = 256,
    HashOnly = 512,
    UseDefaultOSVerCheck = 1024,
    LifetimeSigning = 2048
};
enum UIContext
{
    Execute = 0,
    Install
};

[StructLayout(LayoutKind.Sequential)]

internal struct WINTRUST_DATA : IDisposable
{

    public WINTRUST_DATA(WINTRUST_FILE_INFO fileInfo)
    {

        this.cbStruct = (uint)Marshal.SizeOf(typeof(WINTRUST_DATA));

        pInfoStruct = Marshal.AllocHGlobal(Marshal.SizeOf(typeof(WINTRUST_FILE_INFO)));

        Marshal.StructureToPtr(fileInfo, pInfoStruct, false);

        this.dwUnionChoice = UnionChoice.File;



        pPolicyCallbackData = IntPtr.Zero;

        pSIPCallbackData = IntPtr.Zero;



        dwUIChoice = UiChoice.NoUI;

        fdwRevocationChecks = RevocationCheckFlags.None;

        dwStateAction = StateAction.Ignore;

        hWVTStateData = IntPtr.Zero;

        pwszURLReference = IntPtr.Zero;

        dwProvFlags = TrustProviderFlags.Safer;



        dwUIContext = UIContext.Execute;

    }



    public uint cbStruct;

    public IntPtr pPolicyCallbackData;

    public IntPtr pSIPCallbackData;

    public UiChoice dwUIChoice;

    public RevocationCheckFlags fdwRevocationChecks;

    public UnionChoice dwUnionChoice;

    public IntPtr pInfoStruct;

    public StateAction dwStateAction;

    public IntPtr hWVTStateData;

    private IntPtr pwszURLReference;

    public TrustProviderFlags dwProvFlags;

    public UIContext dwUIContext;



    #region IDisposable Members



    public void Dispose()
    {

        Dispose(true);

    }



    private void Dispose(bool disposing)
    {

        if (dwUnionChoice == UnionChoice.File)
        {

            WINTRUST_FILE_INFO info = new WINTRUST_FILE_INFO();

            Marshal.PtrToStructure(pInfoStruct, info);

            info.Dispose();

            Marshal.DestroyStructure(pInfoStruct, typeof(WINTRUST_FILE_INFO));

        }



        Marshal.FreeHGlobal(pInfoStruct);

    }



    #endregion

}

internal sealed class UnmanagedPointer : IDisposable
{

    private IntPtr m_ptr;

    private AllocMethod m_meth;

    internal UnmanagedPointer(IntPtr ptr, AllocMethod method)
    {

        m_meth = method;

        m_ptr = ptr;

    }



    ~UnmanagedPointer()
    {

        Dispose(false);

    }



    #region IDisposable Members

    private void Dispose(bool disposing)
    {

        if (m_ptr != IntPtr.Zero)
        {

            if (m_meth == AllocMethod.HGlobal)
            {

                Marshal.FreeHGlobal(m_ptr);

            }

            else if (m_meth == AllocMethod.CoTaskMem)
            {

                Marshal.FreeCoTaskMem(m_ptr);

            }

            m_ptr = IntPtr.Zero;

        }

        if (disposing)
        {
            GC.SuppressFinalize(this);
        }
    }

    public void Dispose()
    {
        Dispose(true);
    }

    #endregion

    public static implicit operator IntPtr(UnmanagedPointer ptr)
    {
        return ptr.m_ptr;
    }

}


  public enum HandleType
    {
        Unknown,
        Other,
        File, Directory, SymbolicLink, Key,
        Process, Thread, Job, Session, WindowStation,
        Timer, Desktop, Semaphore, Token,
        Mutant, Section, Event, KeyedEvent, IoCompletion, IoCompletionReserve,
        TpWorkerFactory, AlpcPort, WmiGuid, UserApcReserve,
    }

    public class HandleInfo
    {
        public int ProcessId { get; private set; }
        public System.Diagnostics.Process Process 
        { 
            get 
            {
                if (_process == null)
                {
                    _process = System.Diagnostics.Process.GetProcessById(ProcessId);
                }
                return _process;
            }
        }
        public ushort Handle { get; private set; }
        public int GrantedAccess { get; private set; }
        public byte RawType { get; private set; }

        public HandleInfo(int processId, ushort handle, int grantedAccess, byte rawType)
        {
            ProcessId = processId;
            Handle = handle;
            GrantedAccess = grantedAccess;
            RawType = rawType;
        }

        private static Dictionary<byte, string> _rawTypeMap = new Dictionary<byte, string>();

        private string _name, _typeStr;
        private System.Diagnostics.Process _process;
        private HandleType _type;

        public string Name { get { if (_name == null) initTypeAndName(); return _name; } }
        public string TypeString { get { if (_typeStr == null) initType(); return _typeStr; } }
        public HandleType Type { get { if (_typeStr == null) initType(); return _type; } }

        private void initType()
        {
            if (_rawTypeMap.ContainsKey(RawType))
            {
                _typeStr = _rawTypeMap[RawType];
                _type = HandleTypeFromString(_typeStr);
            }
            else
                initTypeAndName();
        }

        bool _typeAndNameAttempted = false;

        private void initTypeAndName()
        {
            if (_typeAndNameAttempted)
                return;
            _typeAndNameAttempted = true;

            IntPtr sourceProcessHandle = IntPtr.Zero;
            IntPtr handleDuplicate = IntPtr.Zero;
            try
            {
                sourceProcessHandle = NativeMethods.OpenProcess(0x40 /* dup_handle */, true, ProcessId);

                // To read info about a handle owned by another process we must duplicate it into ours
                // For simplicity, current process handles will also get duplicated; remember that process handles cannot be compared for equality
                if (!NativeMethods.DuplicateHandle(sourceProcessHandle, (IntPtr) Handle, NativeMethods.GetCurrentProcess(), out handleDuplicate, 0, false, 2 /* same_access */))
                    return;

                // Query the object type
                if (_rawTypeMap.ContainsKey(RawType))
                    _typeStr = _rawTypeMap[RawType];
                else
                {
                    int length;
                    NativeMethods.NtQueryObject(handleDuplicate, OBJECT_INFORMATION_CLASS.ObjectTypeInformation, IntPtr.Zero, 0, out length);
                    IntPtr ptr = IntPtr.Zero;
                    try
                    {
                        ptr = Marshal.AllocHGlobal(length);
                        if (NativeMethods.NtQueryObject(handleDuplicate, OBJECT_INFORMATION_CLASS.ObjectTypeInformation, ptr, length, out length) != NT_STATUS.STATUS_SUCCESS)
                            return;
                        _typeStr = Marshal.PtrToStringUni((IntPtr) ((long) ptr + 0x58 + 2 * IntPtr.Size));
                        _rawTypeMap[RawType] = _typeStr;
                    }
                    finally
                    {
                        Marshal.FreeHGlobal(ptr);
                    }
                }
                _type = HandleTypeFromString(_typeStr);

                // Query the object name
                if (_typeStr != null && GrantedAccess != 0x0012019f && GrantedAccess != 0x00120189 && GrantedAccess != 0x120089) // dont query some objects that could get stuck
                {
                    int length;
                    NativeMethods.NtQueryObject(handleDuplicate, OBJECT_INFORMATION_CLASS.ObjectNameInformation, IntPtr.Zero, 0, out length);
                    IntPtr ptr = IntPtr.Zero;
                    try
                    {
                        ptr = Marshal.AllocHGlobal(length);
                        if (NativeMethods.NtQueryObject(handleDuplicate, OBJECT_INFORMATION_CLASS.ObjectNameInformation, ptr, length, out length) != NT_STATUS.STATUS_SUCCESS)
                            return;
                        _name = Marshal.PtrToStringUni((IntPtr) ((long) ptr + 2 * IntPtr.Size));

                        if (_typeStr == "File" || _typeStr == "Directory")
                        {
                            _name = GetRegularFileNameFromDevice(_name);
                        }
                    }
                    finally
                    {
                        Marshal.FreeHGlobal(ptr);
                    }
                }
            }
            finally
            {
                NativeMethods.CloseHandle(sourceProcessHandle);
                if (handleDuplicate != IntPtr.Zero)
                    NativeMethods.CloseHandle(handleDuplicate);
            }
        }
        
        private static string GetRegularFileNameFromDevice(string strRawName)
        {
            string strFileName = strRawName;
            foreach (string strDrivePath in Environment.GetLogicalDrives())
            {
                var sbTargetPath = new StringBuilder(NativeMethods.MAX_PATH);
                if (NativeMethods.QueryDosDevice(strDrivePath.Substring(0, 2), sbTargetPath, NativeMethods.MAX_PATH) == 0)
                {
                    return strRawName;
                }
                string strTargetPath = sbTargetPath.ToString();
                if (strFileName.StartsWith(strTargetPath))
                {
                    strFileName = strFileName.Replace(strTargetPath, strDrivePath.Substring(0, 2));
                    break;
                }
            }
            return strFileName;
        }

        public static HandleType HandleTypeFromString(string typeStr)
        {
            switch (typeStr)
            {
                case null: return HandleType.Unknown;
                case "File": return HandleType.File;
                case "IoCompletion": return HandleType.IoCompletion;
                case "TpWorkerFactory": return HandleType.TpWorkerFactory;
                case "ALPC Port": return HandleType.AlpcPort;
                case "Event": return HandleType.Event;
                case "Section": return HandleType.Section;
                case "Directory": return HandleType.Directory;
                case "KeyedEvent": return HandleType.KeyedEvent;
                case "Process": return HandleType.Process;
                case "Key": return HandleType.Key;
                case "SymbolicLink": return HandleType.SymbolicLink;
                case "Thread": return HandleType.Thread;
                case "Mutant": return HandleType.Mutant;
                case "WindowStation": return HandleType.WindowStation;
                case "Timer": return HandleType.Timer;
                case "Semaphore": return HandleType.Semaphore;
                case "Desktop": return HandleType.Desktop;
                case "Token": return HandleType.Token;
                case "Job": return HandleType.Job;
                case "Session": return HandleType.Session;
                case "IoCompletionReserve": return HandleType.IoCompletionReserve;
                case "WmiGuid": return HandleType.WmiGuid;
                case "UserApcReserve": return HandleType.UserApcReserve;
                default: return HandleType.Other;
            }
        }
    }

    public static class HandleUtil
    {
        public static List<HandleInfo> GetHandles()
        {
            List<HandleInfo> handleInfos = new List<HandleInfo>();
            // Attempt to retrieve the handle information
            int length = 0x10000;
            IntPtr ptr = IntPtr.Zero;
            try
            {
                while (true)
                {
                    ptr = Marshal.AllocHGlobal(length);
                    int wantedLength;
                    var result = NativeMethods.NtQuerySystemInformation(SYSTEM_INFORMATION_CLASS.SystemHandleInformation, ptr, length, out wantedLength);
                    if (result == NT_STATUS.STATUS_INFO_LENGTH_MISMATCH)
                    {
                        length = Math.Max(length, wantedLength);
                        Marshal.FreeHGlobal(ptr);
                        ptr = IntPtr.Zero;
                    }
                    else if (result == NT_STATUS.STATUS_SUCCESS)
                        break;
                    else
                        throw new Exception("Failed to retrieve system handle information.");
                }

                long handleCount = IntPtr.Size == 4 ? Marshal.ReadInt32(ptr) : (int) Marshal.ReadInt64(ptr);
                long offset = IntPtr.Size;
                int size = Marshal.SizeOf(typeof(SystemHandleEntry));
                for (int i = 0; i < handleCount; i++)
                {
                    var struc = (SystemHandleEntry) Marshal.PtrToStructure((IntPtr) ((long) ptr + offset), typeof(SystemHandleEntry));

                    var handler = new HandleInfo(struc.OwnerProcessId, struc.Handle, struc.GrantedAccess, struc.ObjectTypeNumber);
                    handleInfos.Add(handler);
                    offset += size;
                }
            }
            finally
            {
                if (ptr != IntPtr.Zero)
                    Marshal.FreeHGlobal(ptr);
            }

            return handleInfos;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct SystemHandleEntry
        {
            public int OwnerProcessId;
            public byte ObjectTypeNumber;
            public byte Flags;
            public ushort Handle;
            public IntPtr Object;
            public int GrantedAccess;
        }
    }

    public enum NT_STATUS
    {
        STATUS_SUCCESS = 0x00000000,
        STATUS_BUFFER_OVERFLOW = unchecked((int) 0x80000005L),
        STATUS_INFO_LENGTH_MISMATCH = unchecked((int) 0xC0000004L)
    }



    public enum SYSTEM_INFORMATION_CLASS
    {
        SystemBasicInformation = 0,
        SystemPerformanceInformation = 2,
        SystemTimeOfDayInformation = 3,
        SystemProcessInformation = 5,
        SystemProcessorPerformanceInformation = 8,
        SystemHandleInformation = 16,
        SystemInterruptInformation = 23,
        SystemExceptionInformation = 33,
        SystemRegistryQuotaInformation = 37,
        SystemLookasideInformation = 45
    }

    public enum OBJECT_INFORMATION_CLASS
    {
        ObjectBasicInformation = 0,
        ObjectNameInformation = 1,
        ObjectTypeInformation = 2,
        ObjectAllTypesInformation = 3,
        ObjectHandleInformation = 4
    }

    [Flags]
    public enum MoveFileFlags
    {
        MOVEFILE_REPLACE_EXISTING           = 0x00000001,
        MOVEFILE_COPY_ALLOWED               = 0x00000002,
        MOVEFILE_DELAY_UNTIL_REBOOT         = 0x00000004,
        MOVEFILE_WRITE_THROUGH              = 0x00000008,
        MOVEFILE_CREATE_HARDLINK            = 0x00000010,
        MOVEFILE_FAIL_IF_NOT_TRACKABLE      = 0x00000020
    }

    public static class NativeMethods
    {
        public const int MAX_PATH = 260;

        [DllImport("ntdll.dll")]
        public static extern NT_STATUS NtQuerySystemInformation(
            [In] SYSTEM_INFORMATION_CLASS SystemInformationClass,
            [In] IntPtr SystemInformation,
            [In] int SystemInformationLength,
            [Out] out int ReturnLength);

        [DllImport("ntdll.dll")]
        public static extern NT_STATUS NtQueryObject(
            [In] IntPtr Handle,
            [In] OBJECT_INFORMATION_CLASS ObjectInformationClass,
            [In] IntPtr ObjectInformation,
            [In] int ObjectInformationLength,
            [Out] out int ReturnLength);

        [DllImport("kernel32.dll")]
        public static extern IntPtr GetCurrentProcess();

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern IntPtr OpenProcess(
            [In] int dwDesiredAccess,
            [In, MarshalAs(UnmanagedType.Bool)] bool bInheritHandle,
            [In] int dwProcessId);

        [ReliabilityContract(Consistency.WillNotCorruptState, Cer.Success)]
        [DllImport("kernel32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool CloseHandle(
            [In] IntPtr hObject);

        [DllImport("kernel32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool DuplicateHandle(
            [In] IntPtr hSourceProcessHandle,
            [In] IntPtr hSourceHandle,
            [In] IntPtr hTargetProcessHandle,
            [Out] out IntPtr lpTargetHandle,
            [In] int dwDesiredAccess,
            [In, MarshalAs(UnmanagedType.Bool)] bool bInheritHandle,
            [In] int dwOptions);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern uint QueryDosDevice(string lpDeviceName, StringBuilder lpTargetPath, int ucchMax);

        [DllImport("kernel32.dll", SetLastError=true, CharSet=CharSet.Unicode)]
        public static extern bool MoveFileEx(string lpExistingFileName, string lpNewFileName,
           MoveFileFlags dwFlags);        

    }

public class ActivationContext
{
    IntPtr hActCtx;
    uint cookie;

        public void CreateAndActivate(string manifest)
        {
            var actCtx = new ACTCTX();
            actCtx.cbSize = Marshal.SizeOf(typeof(ACTCTX));
            actCtx.dwFlags = 0;
            actCtx.lpSource = manifest;
            actCtx.lpResourceName = null;

            hActCtx = CreateActCtx(ref actCtx);
            if(hActCtx == new IntPtr(-1))
            {
                throw new Win32Exception(Marshal.GetLastWin32Error(), "Failed to create activation context.");
            }

            if (!ActivateActCtx(hActCtx, out cookie))
            {
                throw new Win32Exception(Marshal.GetLastWin32Error(), "Failed to activate activation context.");
            }
        }

        public void DeactivateAndFree()
        {
            DeactivateActCtx(0, cookie);
            ReleaseActCtx(hActCtx);
        }

       [DllImport("kernel32.dll")]
        private static extern IntPtr CreateActCtx(ref ACTCTX actctx);

        [StructLayout(LayoutKind.Sequential)]
        private struct ACTCTX
        {
            public int cbSize;
            public uint dwFlags;
            public string lpSource;
            public ushort wProcessorArchitecture;
            public ushort wLangId;
            public string lpAssemblyDirectory;
            public string lpResourceName;
            public string lpApplicationName;
        }

        [DllImport("Kernel32.dll", SetLastError = true)]
        private extern static bool ActivateActCtx(IntPtr hActCtx, out uint lpCookie);

        [DllImport("Kernel32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool DeactivateActCtx(int dwFlags, uint lpCookie);

        [DllImport("Kernel32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool ReleaseActCtx(IntPtr hActCtx);

        private const uint ACTCTX_FLAG_PROCESSOR_ARCHITECTURE_VALID = 0x001;
        private const uint ACTCTX_FLAG_LANGID_VALID = 0x002;
        private const uint ACTCTX_FLAG_ASSEMBLY_DIRECTORY_VALID = 0x004;
        private const uint ACTCTX_FLAG_RESOURCE_NAME_VALID = 0x008;
        private const uint ACTCTX_FLAG_SET_PROCESS_DEFAULT = 0x010;
        private const uint ACTCTX_FLAG_APPLICATION_NAME_VALID = 0x020;
        private const uint ACTCTX_FLAG_HMODULE_VALID = 0x080;

        private const UInt16 RT_MANIFEST = 24;
        private const UInt16 CREATEPROCESS_MANIFEST_RESOURCE_ID = 1;
        private const UInt16 ISOLATIONAWARE_MANIFEST_RESOURCE_ID = 2;
        private const UInt16 ISOLATIONAWARE_NOSTATICIMPORT_MANIFEST_RESOURCE_ID = 3;

        private const uint FORMAT_MESSAGE_ALLOCATE_BUFFER = 0x00000100;
        private const uint FORMAT_MESSAGE_IGNORE_INSERTS = 0x00000200;
        private const uint FORMAT_MESSAGE_FROM_SYSTEM = 0x00001000;
        }

}

' 