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
                    WellKnownObjectMode.SingleCall);
        }

        public static void Inject(int pid, string entryPoint, string dll, string typeName, string scriptBlock, string modulePath, string additionalCode, bool log)
        {
            var assembly = System.Reflection.Assembly.GetExecutingAssembly();
                
            RemoteHooking.Inject(
                            pid,
                            assembly.Location, // 32-bit version (the same because AnyCPU)
                            assembly.Location, // 64-bit version (the same because AnyCPU)
                            _channelName,
                            entryPoint,
                            dll,
                            typeName,
                            scriptBlock,
                            modulePath,
                            additionalCode,
                            log);
        }

        public void ReportError(
            Int32 InClientPID,
            Exception e)
        {
            throw new Exception(string.Format("Process [{0}] reported error an error!"), e);
        }

        public void WriteHost(
            string e)
        {
            Console.WriteLine(e);
        }
    }


    public class HookInjection : EasyHook.IEntryPoint
    {
        public Runspace Runspace;
        public HookInterface Interface = null;

        public HookInjection(
            RemoteHooking.IContext InContext,
            String InChannelName,
            String entryPoint,
            String dll,
            String returnType,
            String scriptBlock,
            String modulePath,
            String additionalCode,
            bool eventLog)
        {
            Log("Opening hook interface channel...", eventLog);
            Interface = RemoteHooking.IpcConnectClient<HookInterface>(InChannelName);
            try
            {
                Runspace = RunspaceFactory.CreateRunspace();
                Runspace.Open();

                //Runspace.SessionStateProxy.SetVariable("HookInterface", Interface);
            }
            catch (Exception ex)
            {
                Log("Failed to open PowerShell runspace." + ex.Message, eventLog);
                Interface.ReportError(RemoteHooking.GetCurrentProcessId(), ex);
            }
        }

        public void Run(
            RemoteHooking.IContext InContext,
            String channelName,
            String entryPoint,
            String dll,
            String returnType,
            String scriptBlock,
            String modulePath,
            String additionalCode,
            bool eventLog)
        {
            try
            {
                Log(String.Format("Executing Set-Hook -Local -EntryPoint '{0}' -Dll '{1}' -ReturnType '{2}' -ScriptBlock '{3}' ", entryPoint, dll, returnType, scriptBlock), eventLog);
                using (var ps = PowerShell.Create())
                {
                    ps.Runspace = Runspace;
                    ps.AddCommand("Import-Module");
                    ps.AddArgument(modulePath);
                    ps.Invoke();
                    ps.Commands.Clear();

                    ps.AddCommand("Set-Hook");
                    ps.AddParameter("EntryPoint", entryPoint);
                    ps.AddParameter("Dll", dll);
                    ps.AddParameter("ReturnType", returnType);
                    ps.AddParameter("AdditionalCode", additionalCode);

                    var sb = ScriptBlock.Create(scriptBlock);

                    ps.AddParameter("ScriptBlock", sb);
                    ps.Invoke();

                    foreach (var record in ps.Streams.Error)
                    {
                        Log("Caught exception " + record.Exception.Message, eventLog);
                    }
                }

                RemoteHooking.WakeUpProcess();
                new System.Threading.ManualResetEvent(false).WaitOne();
            }
            catch (Exception e)
            {
                Log("Caught exception " + e.Message, eventLog);
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

        private static void Log(string message, bool shouldLog)
        {
            if (!shouldLog) return;
            try
            {
                if (!System.Diagnostics.EventLog.SourceExists("PoshHook"))
                {
                    System.Diagnostics.EventLog.CreateEventSource("PoshHook", "Application");
                }
                
                var log = new System.Diagnostics.EventLog("Application", ".", "PoshHook");
                log.WriteEntry(message);
            }
            catch
            {
                
            }

        }
    }
}