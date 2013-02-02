function Get-ComputerSID
{
    ((get-wmiobject -query "Select *from Win32_UserAccount Where LocalAccount =TRUE").SID -replace "\d+$","" -replace ".$")[0]
}
