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

	$desktops
}

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