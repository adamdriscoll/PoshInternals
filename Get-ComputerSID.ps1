<#
.Synopsis
   Gets the SID of the computer.
.DESCRIPTION
   Gets the SID of the computer.
.EXAMPLE
   Get-ComputerSID
#>
function Get-ComputerSID
{
    ((get-wmiobject -query "Select *from Win32_UserAccount Where LocalAccount =TRUE").SID -replace "\d+$","" -replace ".$")[0]
}
