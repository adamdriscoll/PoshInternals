using System;
using System.Collections.Generic;
using System.Text;
using System.Threading;
using System.IO;
using System.Runtime.InteropServices;
using EasyHook;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Runtime.Remoting;
using System.Runtime.Remoting.Channels.Ipc;

namespace PoshInternals
{
    public class HookInterface : MarshalByRefObject
    {
        private static string _channelName;

        public Runspace Runspace;

        public static IpcServerChannel CreateServer()
        {
            return RemoteHooking.IpcCreateServer<HookInterface>(
                    ref _channelName,
                    WellKnownObjectMode.Singleton);
        }

        public static void Inject(int pid, string entryPoint, string dll, string typeName, string scriptBlock, string modulePath)
        {
            var hookDll = Path.Combine(Path.GetTempPath(), "HookInject.dll");

            RemoteHooking.Inject(
                            pid,
                            hookDll, // 32-bit version (the same because AnyCPU)
                            hookDll, // 64-bit version (the same because AnyCPU)
                            _channelName,
                            entryPoint,
                            dll,
                            typeName,
                            scriptBlock,
                            modulePath);
        }

        public void ReportError(
            Int32 InClientPID,
            Exception e)
        {
            throw new Exception(string.Format("Process [{0}] reported error an error!"), e);
        }
    }


    public class HookInjection : EasyHook.IEntryPoint
    {
        public HookInterface Interface = null;
        public LocalHook CreateFileHook = null;
        Stack<String> Queue = new Stack<string>();

        public HookInjection(
            RemoteHooking.IContext InContext,
            String InChannelName)
        {
            Interface = RemoteHooking.IpcConnectClient<HookInterface>(InChannelName);
        }

        public void Run(
            RemoteHooking.IContext InContext,
            String entryPoint,
            String dll,
            String typeName,
            String scriptBlock,
            String modulePath)
        {
            try
            {
                using (var ps = PowerShell.Create())
                {
                    ps.AddCommand("Import-Module");
                    ps.AddArgument(modulePath);
                    ps.Invoke();
                    ps.Commands.Clear();

                    ps.AddCommand("Set-Hook");
                    ps.AddParameter("Local");
                    ps.AddParameter("EntryPoint", entryPoint);
                    ps.AddParameter("Dll", dll);
                    ps.AddParameter("TypeName", typeName);

                    var sb = ScriptBlock.Create(scriptBlock);

                    ps.AddParameter("ScriptBlock", sb);
                    ps.Invoke();
                }
            }
            catch (Exception e)
            {
                try
                {
                    Interface.ReportError(RemoteHooking.GetCurrentProcessId(), e);
                }
                catch
                {
                    
                }

                return;
            }
        }
    }
}