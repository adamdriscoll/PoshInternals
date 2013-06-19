<#
.Synopsis
   Returns the desktops for this Windows Station.
.DESCRIPTION
   Returns the desktops for this Windows Station. 
.EXAMPLE
   Get-Desktop
.EXAMPLE
   Get-Desktop -Name Default
#>
function Get-Desktop
{
    param(
    # The name of the desktop to return
    [String]$Name = "*"
    )
    $windowStation = [PoshInternals.User32]::GetProcessWindowStation()
	if ($windowStation -eq [IntPtr]::Zero) 
    {
        throw (New-Object System.ComponentModel.Win32Exception)
    }

    $global:desktops = @()
	if (-not [PoshInternals.User32]::EnumDesktops($windowStation, {$global:desktops += $args[0]; $true }, [IntPtr]::Zero))
    {
        Write-Error "Failed to enumerate desktops!"
        return
    }

    $AccessRights = [PoshInternals.Constants]::DESKTOP_JOURNALRECORD -bor [PoshInternals.Constants]::DESKTOP_JOURNALPLAYBACK -bor [PoshInternals.Constants]::DESKTOP_CREATEWINDOW -bor [PoshInternals.Constants]::DESKTOP_ENUMERATE -bor [PoshInternals.Constants]::DESKTOP_WRITEOBJECTS -bor [PoshInternals.Constants]::DESKTOP_SWITCHDESKTOP -bor [PoshInternals.Constants]::DESKTOP_CREATEMENU -bor [PoshInternals.Constants]::DESKTOP_HOOKCONTROL -bor [PoshInternals.Constants]::DESKTOP_READOBJECTS

    $desktops | Where Name -Like $Name | ForEach-Object {
        $Handle = [PoshInternals.User32]::OpenDesktop($_, 0, $true, $AccessRights)

        [PSCustomObject]@{ Handle=$Handle;Name=$_}
    }
}

<#
.Synopsis
   Creates a new desktop in the current process's win station.
.DESCRIPTION
   Creates a new desktop in the current process's win station.
.EXAMPLE
   New-Desktop -Name Desktop2
#>
function New-Desktop
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [String]$Name
    )

    $AccessRights = [PoshInternals.Constants]::DESKTOP_JOURNALRECORD -bor [PoshInternals.Constants]::DESKTOP_JOURNALPLAYBACK -bor [PoshInternals.Constants]::DESKTOP_CREATEWINDOW -bor [PoshInternals.Constants]::DESKTOP_ENUMERATE -bor [PoshInternals.Constants]::DESKTOP_WRITEOBJECTS -bor [PoshInternals.Constants]::DESKTOP_SWITCHDESKTOP -bor [PoshInternals.Constants]::DESKTOP_CREATEMENU -bor [PoshInternals.Constants]::DESKTOP_HOOKCONTROL -bor [PoshInternals.Constants]::DESKTOP_READOBJECTS
    $DesktopHandle = [PoshInternals.User32]::CreateDesktop($Name, [IntPtr]::Zero, [IntPtr]::Zero, 0, $AccessRights, [IntPtr]::Zero)

    if ($DesktopHandle -eq [IntPtr]::Zero)
    {
        Write-Error "Failed to create desktop!"
    }
    else
    {
        $Desktop = [PSCustomObject]@{ Handle=$DesktopHandle;Name=$Name}
        $Desktop | Add-Member -MemberType ScriptMethod -Name Close -Value { [PoshInternals.User32]::CloseDesktop($this) } -PassThru
    }
}

function Show-Desktop
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeLine=$true, ParameterSetName="Desktop")]
        [PSObject]$Desktop,
        [Parameter(Mandatory, ValueFromPipeLine=$true, ParameterSetName="Name")]
        [string]$Name
    )

    Process
    {
        if ($Desktop -eq $null)
        {
            $Desktop = Get-Desktop -Name $Name
        }

        if ($Desktop -eq $null)
        {
            Write-Error "Failed to find desktop"
            return
        }

        if (-not [PoshInternals.User32]::SwitchDesktop($Desktop.Handle))
        {
            throw (New-Object System.ComponentModel.Win32Exception)
        }
    }
}

function Start-Process
{
    [CmdletBinding(DefaultParameterSetName='Default', HelpUri='http://go.microsoft.com/fwlink/?LinkID=135261')]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [Alias('PSPath')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${FilePath},

        [Parameter(Position=1)]
        [Alias('Args')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${ArgumentList},

        [Parameter(ParameterSetName='Default')]
        [Alias('RunAs')]
        [ValidateNotNullOrEmpty()]
        [pscredential]
        ${Credential},

        [ValidateNotNullOrEmpty()]
        [string]
        ${WorkingDirectory},

        [Parameter(ParameterSetName='Default')]
        [Alias('Lup')]
        [switch]
        ${LoadUserProfile},

        [Parameter(ParameterSetName='Default')]
        [Alias('nnw')]
        [switch]
        ${NoNewWindow},

        [switch]
        ${PassThru},

        [Parameter(ParameterSetName='Default')]
        [Alias('RSE')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${RedirectStandardError},

        [Parameter(ParameterSetName='Default')]
        [Alias('RSI')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${RedirectStandardInput},

        [Parameter(ParameterSetName='Default')]
        [Alias('RSO')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${RedirectStandardOutput},

        [Parameter(ParameterSetName='UseShellExecute')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Verb},

        [switch]
        ${Wait},

        [ValidateNotNullOrEmpty()]
        [System.Diagnostics.ProcessWindowStyle]
        ${WindowStyle},

        [Parameter(ParameterSetName='Default')]
        [switch]
        ${UseNewEnvironment},
        
        [string]
        ${Desktop})

    begin
    {
        try {
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
            {
                $PSBoundParameters['OutBuffer'] = 1
            }
            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Start-Process', [System.Management.Automation.CommandTypes]::Cmdlet)

            $scriptCmd = {& $wrappedCmd @PSBoundParameters }
            $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)
        } catch {
            throw
        }
    }

    process
    {
        try {
            if ($PSBoundParameters['Desktop'])
            {
                $pInfo = new-object PoshInternals.PROCESS_INFORMATION
                $sInfo = new-object PoshInternals.STARTUPINFO
                $pSec = new-object PoshInternals.SECURITY_ATTRIBUTES
                $tSec = new-object PoshInternals.SECURITY_ATTRIBUTES

                $sInfo.lpDesktop = $Desktop

                $pSec.nLength = [System.InteropServices.Marshal]::SizeOf($pSec)
                $tSec.nLength = [System.InteropServices.Marshal]::($tSec)

                if (-not [PoshInternals.Kernel32]::CreateDesktop($FilePath, $ArgumentList, [ref] $pSec, [ref] $tSec, 0,  [IntPtr]::Zero, $WorkingDirectory, $sInfo, [ref]$pInfo))
                {
                    throw (New-Object System.ComponentModel.Win32Exception)
                }
            }
            else
            {
                $steppablePipeline.Process($_)
            }
        } catch {
            throw
        }
    }

    end
    {
        try {
            $steppablePipeline.End()
        } catch {
            throw
        }
    }
    <#

    .ForwardHelpTargetName Start-Process
    .ForwardHelpCategory Cmdlet

    #>

}