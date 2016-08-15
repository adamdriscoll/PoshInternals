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
    [Parameter(Position=0)]
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

    $desktops | Where { $_ -Like $Name } | ForEach-Object {
        $Handle = [PoshInternals.User32]::OpenDesktop($_, 0, $true, [PoshInternals.ACCESS_MASK]::DESKTOP_ALL)

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
        [Parameter(Mandatory, Position=0)]
        [String]$Name,
        [Switch]$NoExplorer
    )

    $DesktopHandle = [PoshInternals.User32]::CreateDesktop($Name, [IntPtr]::Zero, [IntPtr]::Zero, 0, [PoshInternals.ACCESS_MASK]::DESKTOP_ALL, [IntPtr]::Zero)

    if ($DesktopHandle -eq [IntPtr]::Zero)
    {
        $ex = New-Object System.ComponentModel.Win32Exception

        Write-Error "Failed to create desktop! $($ex.Message)"
    }
    else
    {
        if (-not $NoExplorer)
        {
            Start-Process explorer.exe -Desktop $Name
        }

        $Desktop = [PSCustomObject]@{ Handle=$DesktopHandle;Name=$Name}
        $Desktop | Add-Member -MemberType ScriptMethod -Name Close -Value { [PoshInternals.User32]::CloseDesktop($this) } -PassThru
    }
}
<#
.Synopsis
   Shows the specified desktop.
.DESCRIPTION
   This cmdlet will change the current input desktop to the one specified. If the NoExplorer switch was specified
   on New-Desktop, then there will be nothing running in the newly created desktop. Use Start-Process with the 
   Desktop parameter, before changing desktops, to start a proces in the target desktop.
.EXAMPLE
   Show-Desktop -Name Desktop2
#>
function Show-Desktop
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeLine=$true, ParameterSetName="Desktop")]
        [PSObject]$Desktop,
        [Parameter(Mandatory, ValueFromPipeLine=$true, ParameterSetName="Name", Position=0)]
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
        
        [Parameter(ParameterSetName='AltDesktop')]
        [string]
        ${Desktop})

    begin
    {
        try {
            if (-not $PSBoundParameters['Desktop'])
            {
                $outBuffer = $null
                if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
                {
                    $PSBoundParameters['OutBuffer'] = 1
                }
                $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Start-Process', [System.Management.Automation.CommandTypes]::Cmdlet)

                $scriptCmd = {& $wrappedCmd @PSBoundParameters }
                $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
                $steppablePipeline.Begin($PSCmdlet)
            }
        } catch {
            throw
        }
    }

    process
    {
        try {
            if ($PSBoundParameters['Desktop'])
            {
                $CommandLine = "$FilePath $ArgumentList"

                $Process = [PoshInternals.CreateProcessHelper]::CreateProcess($CommandLine, $Desktop)
                if ($PassThru)
                {
                    $Process
                }

                if ($Wait)
                {
                    $Process.WaitForExit()
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
        if (-not $PSBoundParameters['Desktop'])
        {
            try {
                $steppablePipeline.End()
            } catch {
                throw
            }
        }
    }
    <#

    .ForwardHelpTargetName Start-Process
    .ForwardHelpCategory Cmdlet

    #>

}