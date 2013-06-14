﻿Add-Type -TypeDefinition '
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;
using System.ComponentModel;
using System.Runtime.ConstrainedExecution;
using System.Runtime.InteropServices;

namespace PoshInternals {
    //-------------Enums

    public enum AllocMethod
    {
        HGlobal,
        CoTaskMem
    }

    public enum FileSystemCacheFlags
    {
        FILE_CACHE_MAX_HARD_DISABLE = 0x2,
        FILE_CACHE_MAX_HARD_ENABLE = 0x1,
        FILE_CACHE_MIN_HARD_DISABLE = 0x8,
        FILE_CACHE_MIN_HARD_ENABLE = 0x4
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

    public enum MINIDUMP_TYPE 
    { 
      MiniDumpNormal                          = 0x00000000,
      MiniDumpWithDataSegs                    = 0x00000001,
      MiniDumpWithFullMemory                  = 0x00000002,
      MiniDumpWithHandleData                  = 0x00000004,
      MiniDumpFilterMemory                    = 0x00000008,
      MiniDumpScanMemory                      = 0x00000010,
      MiniDumpWithUnloadedModules             = 0x00000020,
      MiniDumpWithIndirectlyReferencedMemory  = 0x00000040,
      MiniDumpFilterModulePaths               = 0x00000080,
      MiniDumpWithProcessThreadData           = 0x00000100,
      MiniDumpWithPrivateReadWriteMemory      = 0x00000200,
      MiniDumpWithoutOptionalData             = 0x00000400,
      MiniDumpWithFullMemoryInfo              = 0x00000800,
      MiniDumpWithThreadInfo                  = 0x00001000,
      MiniDumpWithCodeSegs                    = 0x00002000,
      MiniDumpWithoutAuxiliaryState           = 0x00004000,
      MiniDumpWithFullAuxiliaryState          = 0x00008000,
      MiniDumpWithPrivateWriteCopyMemory      = 0x00010000,
      MiniDumpIgnoreInaccessibleMemory        = 0x00020000,
      MiniDumpWithTokenInformation            = 0x00040000,
      MiniDumpWithModuleHeaders               = 0x00080000,
      MiniDumpFilterTriage                    = 0x00100000,
      MiniDumpValidTypeFlags                  = 0x001fffff
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

    public enum NT_STATUS
    {
        STATUS_SUCCESS = 0x00000000,
        STATUS_BUFFER_OVERFLOW = unchecked((int) 0x80000005L),
        STATUS_INFO_LENGTH_MISMATCH = unchecked((int) 0xC0000004L)
    }

    public enum OBJECT_INFORMATION_CLASS
    {
        ObjectBasicInformation = 0,
        ObjectNameInformation = 1,
        ObjectTypeInformation = 2,
        ObjectAllTypesInformation = 3,
        ObjectHandleInformation = 4
    }

    public enum RevocationCheckFlags
    {
        None = 0,
        WholeChain
    }

    public enum StateAction
    {
        Ignore = 0,
        Verify,
        Close,
        AutoCache,
        AutoCacheFlush
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
    }

    public enum UiChoice
    {
        All = 1,
        NoUI,
        NoBad,
        NoGood
    }

    public enum UIContext
    {
        Execute = 0,
        Install
    }

    public enum UnionChoice
    {
        File = 1,
        Catalog,
        Blob,
        Signer,
        Cert
    }

    //-------------End Enums

    //----------Structures

    [StructLayout(LayoutKind.Sequential)]
    public struct ACTCTX
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

    [StructLayout(LayoutKind.Sequential, Pack = 4)]
    public struct MINIDUMP_EXCEPTION_INFORMATION
    {
        public uint ThreadId;
        public IntPtr ExceptionPointers;
        public int ClientPointers;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct SystemHandleEntry
    {
        public int OwnerProcessId;
        public byte ObjectTypeNumber;
        public byte Flags;
        public ushort Handle;
        public IntPtr Object;
        public int GrantedAccess;
    }

    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    public struct TokPriv1Luid
    {
        public int Count;
        public long Luid;
        public int Attr;
    }

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
    }

    //------------End Structures

    //------------Native Methods

    public static class Advapi32
    {
        [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
        public static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall,
            ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);
  
        [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
        public static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);

        [DllImport("advapi32.dll", SetLastError = true)]
        public static extern bool LookupPrivilegeValue(string host, string name, ref long pluid);
    }

    public static class Kernel32
    {
        [DllImport("Kernel32.dll", SetLastError = true)]
        public extern static bool ActivateActCtx(IntPtr hActCtx, out uint lpCookie);

        [ReliabilityContract(Consistency.WillNotCorruptState, Cer.Success)]
        [DllImport("kernel32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool CloseHandle(
            [In] IntPtr hObject);

        [DllImport("Kernel32.dll", SetLastError = true, CharSet = CharSet.Auto)]
        public static extern IntPtr CreateFile(
            string fileName,
            [MarshalAs(UnmanagedType.U4)] FileAccess fileAccess,
            [MarshalAs(UnmanagedType.U4)] FileShare fileShare,
            int securityAttributes,
            [MarshalAs(UnmanagedType.U4)] FileMode creationDisposition,
            int flags,
            IntPtr template);

        [DllImport("kernel32.dll")]
        public static extern IntPtr CreateActCtx(ref ACTCTX actctx);

        [DllImport("Kernel32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool DeactivateActCtx(int dwFlags, uint lpCookie);

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

        [DllImport("kernel32.dll")]
        public static extern IntPtr GetCurrentProcess();

        [System.Runtime.InteropServices.DllImportAttribute("kernel32.dll", SetLastError=true)]
        [return: System.Runtime.InteropServices.MarshalAs(System.Runtime.InteropServices.UnmanagedType.Bool)]
        public static extern bool GetSystemFileCacheSize(
            ref uint lpMinimumFileCacheSize,
            ref uint lpMaximumFileCacheSize,
            ref int lpFlags
            );

        [DllImport("kernel32.dll", SetLastError=true, CharSet=CharSet.Unicode)]
        public static extern bool MoveFileEx(string lpExistingFileName, string lpNewFileName,
           MoveFileFlags dwFlags);    

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern IntPtr OpenProcess(
            [In] int dwDesiredAccess,
            [In, MarshalAs(UnmanagedType.Bool)] bool bInheritHandle,
            [In] int dwProcessId);

        [DllImport("Kernel32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool ReleaseActCtx(IntPtr hActCtx);

        [System.Runtime.InteropServices.DllImportAttribute("kernel32.dll", SetLastError=true)]
        [return: System.Runtime.InteropServices.MarshalAs(System.Runtime.InteropServices.UnmanagedType.Bool)]
        public static extern bool SetSystemFileCacheSize(
            uint lpMinimumFileCacheSize,
            uint lpMaximumFileCacheSize,
            int lpFlags
            );

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern uint QueryDosDevice(string lpDeviceName, StringBuilder lpTargetPath, int ucchMax);
        
        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool SetProcessWorkingSetSize( 
            IntPtr proc, 
            int min, 
            int max 
            );
    }

    public static class DbgHelp
    {
        [DllImport("Dbghelp.dll")]
        public static extern bool MiniDumpWriteDump(IntPtr hProcess, uint ProcessId, IntPtr hFile, MINIDUMP_TYPE DumpType, IntPtr ExceptionParam, IntPtr UserStreamParam, IntPtr CallbackParam);
    }

    public static class NtDll
    {
        [DllImport("ntdll.dll")]
        public static extern NT_STATUS NtQueryObject(
            [In] IntPtr Handle,
            [In] OBJECT_INFORMATION_CLASS ObjectInformationClass,
            [In] IntPtr ObjectInformation,
            [In] int ObjectInformationLength,
            [Out] out int ReturnLength);

        [DllImport("ntdll.dll")]
        public static extern NT_STATUS NtQuerySystemInformation(
            [In] SYSTEM_INFORMATION_CLASS SystemInformationClass,
            [In] IntPtr SystemInformation,
            [In] int SystemInformationLength,
            [Out] out int ReturnLength);
    }

    public static class WinTrust
    {
        [DllImport("Wintrust.dll", PreserveSig = true, SetLastError = false)]
        public static extern uint WinVerifyTrust(IntPtr hWnd, IntPtr pgActionID, IntPtr pWinTrustData);
    }

    //------------End Native Methods

    public static class Constants
    {
        public const uint ACTCTX_FLAG_PROCESSOR_ARCHITECTURE_VALID = 0x001;
        public const uint ACTCTX_FLAG_LANGID_VALID = 0x002;
        public const uint ACTCTX_FLAG_ASSEMBLY_DIRECTORY_VALID = 0x004;
        public const uint ACTCTX_FLAG_RESOURCE_NAME_VALID = 0x008;
        public const uint ACTCTX_FLAG_SET_PROCESS_DEFAULT = 0x010;
        public const uint ACTCTX_FLAG_APPLICATION_NAME_VALID = 0x020;
        public const uint ACTCTX_FLAG_HMODULE_VALID = 0x080;

        public const int FILE_CACHE_MAX_HARD_ENABLE = 1;
        public const int FILE_CACHE_MIN_HARD_ENABLE = 4;

        public const int MAX_PATH = 260;

        public const UInt16 RT_MANIFEST = 24;
        public const UInt16 CREATEPROCESS_MANIFEST_RESOURCE_ID = 1;
        public const UInt16 ISOLATIONAWARE_MANIFEST_RESOURCE_ID = 2;
        public const UInt16 ISOLATIONAWARE_NOSTATICIMPORT_MANIFEST_RESOURCE_ID = 3;

        public const uint FORMAT_MESSAGE_ALLOCATE_BUFFER = 0x00000100;
        public const uint FORMAT_MESSAGE_IGNORE_INSERTS = 0x00000200;
        public const uint FORMAT_MESSAGE_FROM_SYSTEM = 0x00001000;

        public const int SE_PRIVILEGE_ENABLED = 0x00000002;
        public const int SE_PRIVILEGE_DISABLED = 0x00000000;
        public const int TOKEN_QUERY = 0x00000008;
        public const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;
    }

    //------------Helper Classes

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

            hActCtx = Kernel32.CreateActCtx(ref actCtx);
            if(hActCtx == new IntPtr(-1))
            {
                throw new Win32Exception(Marshal.GetLastWin32Error(), "Failed to create activation context.");
            }

            if (!Kernel32.ActivateActCtx(hActCtx, out cookie))
            {
                throw new Win32Exception(Marshal.GetLastWin32Error(), "Failed to activate activation context.");
            }
        }

        public void DeactivateAndFree()
        {
            Kernel32.DeactivateActCtx(0, cookie);
            Kernel32.ReleaseActCtx(hActCtx);
        }
    }

    public class AdjustPrivilege
    {
        public static bool EnablePrivilege(long processHandle, string privilege, bool disable)
        {
            bool retVal;
            TokPriv1Luid tp;
            IntPtr hproc = new IntPtr(processHandle);
            IntPtr htok = IntPtr.Zero;

            retVal = Advapi32.OpenProcessToken(hproc, Constants.TOKEN_ADJUST_PRIVILEGES | Constants.TOKEN_QUERY, ref htok);
            tp.Count = 1;
            tp.Luid = 0;

            if(disable)
            {
                tp.Attr = Constants.SE_PRIVILEGE_DISABLED;
            }
            else
            {
                tp.Attr = Constants.SE_PRIVILEGE_ENABLED;
            }

            retVal = Advapi32.LookupPrivilegeValue(null, privilege, ref tp.Luid);
            retVal = Advapi32.AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);

            return retVal;
        }
    }

    public static class AuthenticodeTools
    {
        private static uint WinVerifyTrust(string fileName)
        {
            Guid wintrust_action_generic_verify_v2 = new Guid("{00AAC56B-CD44-11d0-8CC2-00C04FC295EE}");
            uint result=0;
            using (WINTRUST_FILE_INFO fileInfo = new WINTRUST_FILE_INFO(fileName, Guid.Empty))
            using (UnmanagedPointer guidPtr = new UnmanagedPointer(Marshal.AllocHGlobal(Marshal.SizeOf(typeof (Guid))), AllocMethod.HGlobal))
            using (UnmanagedPointer wvtDataPtr = new UnmanagedPointer(Marshal.AllocHGlobal(Marshal.SizeOf(typeof (WINTRUST_DATA))), AllocMethod.HGlobal))
            {
                WINTRUST_DATA data = new WINTRUST_DATA(fileInfo);
                IntPtr pGuid = guidPtr;
                IntPtr pData = wvtDataPtr;
                Marshal.StructureToPtr(wintrust_action_generic_verify_v2, pGuid, true);
                Marshal.StructureToPtr(data, pData, true);
                result = WinTrust.WinVerifyTrust(IntPtr.Zero, pGuid, pData);
            }
            return result;

        }

        public static bool IsTrusted(string fileName)
        {
            return WinVerifyTrust(fileName) == 0;
        }
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

        public void Close()
        {
            Kernel32.CloseHandle(new IntPtr(Handle));
        }

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
                sourceProcessHandle = Kernel32.OpenProcess(0x40 /* dup_handle */, true, ProcessId);

                // To read info about a handle owned by another process we must duplicate it into ours
                // For simplicity, current process handles will also get duplicated; remember that process handles cannot be compared for equality
                if (!Kernel32.DuplicateHandle(sourceProcessHandle, (IntPtr) Handle, Kernel32.GetCurrentProcess(), out handleDuplicate, 0, false, 2 /* same_access */))
                    return;

                // Query the object type
                if (_rawTypeMap.ContainsKey(RawType))
                    _typeStr = _rawTypeMap[RawType];
                else
                {
                    int length;
                    NtDll.NtQueryObject(handleDuplicate, OBJECT_INFORMATION_CLASS.ObjectTypeInformation, IntPtr.Zero, 0, out length);
                    IntPtr ptr = IntPtr.Zero;
                    try
                    {
                        ptr = Marshal.AllocHGlobal(length);
                        if (NtDll.NtQueryObject(handleDuplicate, OBJECT_INFORMATION_CLASS.ObjectTypeInformation, ptr, length, out length) != NT_STATUS.STATUS_SUCCESS)
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
                    NtDll.NtQueryObject(handleDuplicate, OBJECT_INFORMATION_CLASS.ObjectNameInformation, IntPtr.Zero, 0, out length);
                    IntPtr ptr = IntPtr.Zero;
                    try
                    {
                        ptr = Marshal.AllocHGlobal(length);
                        if (NtDll.NtQueryObject(handleDuplicate, OBJECT_INFORMATION_CLASS.ObjectNameInformation, ptr, length, out length) != NT_STATUS.STATUS_SUCCESS)
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
                Kernel32.CloseHandle(sourceProcessHandle);
                if (handleDuplicate != IntPtr.Zero)
                    Kernel32.CloseHandle(handleDuplicate);
            }
        }
        
        private static string GetRegularFileNameFromDevice(string strRawName)
        {
            string strFileName = strRawName;
            foreach (string strDrivePath in Environment.GetLogicalDrives())
            {
                var sbTargetPath = new StringBuilder(Constants.MAX_PATH);
                if (Kernel32.QueryDosDevice(strDrivePath.Substring(0, 2), sbTargetPath, Constants.MAX_PATH) == 0)
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
                    var result = NtDll.NtQuerySystemInformation(SYSTEM_INFORMATION_CLASS.SystemHandleInformation, ptr, length, out wantedLength);
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
    }

    public class SystemCache
    {
        public static uint GetMinFileCacheSize()
        {
            uint min = 0, max = 0;
            int flags = 0;
            if (!Kernel32.GetSystemFileCacheSize(ref min, ref max, ref flags))
            {
                throw new System.ComponentModel.Win32Exception();
            }

            return min;
        }

        public static uint GetMaxFileCacheSize()
        {
            uint min = 0, max = 0;
            int flags = 0;
            if (!Kernel32.GetSystemFileCacheSize(ref min, ref max, ref flags))
            {
                throw new System.ComponentModel.Win32Exception();
            }

            return max;
        }

        public static int GetFlags()
        {
            uint min = 0, max = 0;
            int flags = 0;
            if (!Kernel32.GetSystemFileCacheSize(ref min, ref max, ref flags))
            {
                throw new System.ComponentModel.Win32Exception();
            }

            return flags;
        }

        public static void SetCacheFileSize(uint min, uint max, int flags)
        {
            if (!Kernel32.SetSystemFileCacheSize(min, max, flags))
            {
                throw new System.ComponentModel.Win32Exception();
            }
        }
    }

    public sealed class UnmanagedPointer : IDisposable
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


}

' 