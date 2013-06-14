<#
.Synopsis
   Gets the current Windows Cache Manager file system cache sizes and flags.
.DESCRIPTION
   Gets the current Windows Cache Manager file system cache sizes and flags. 

   This cmdlet returns the maximum, minimum and flags used to specify the limits for the 
   system's file system cache. 
.EXAMPLE
   Get-FileSystemCache
#>
function Get-FileSystemCache
{
    [PSCustomObject]@{MaxFileCacheSize=[PoshInternals.SystemCache]::GetMaxFileCacheSize();MinFileCacheSize=[PoshInternals.SystemCache]::GetMaxFileCacheSize();Flags=[PoshInternals.SystemCache]::GetFlags()}
}
<#
.Synopsis
   Set the current Windows Cache Manager file system cache sizes and flags.
.DESCRIPTION
   SEt the current Windows Cache Manager file system cache sizes and flags. 

   This cmdlet sets the maximum, minimum and flags used to specify the limits for the 
   system's file system cache. 
.EXAMPLE
   Get-FileSystemCache
#>
function Set-FileSystemCache
{
    param(
    # The minimum number of bytes that can be stored in the file system cache.
    [uint32]$Minimum,
    # The maximum number of bytes that can be stored in the file system cache. 
    [uint32]$Maximum,
    # Sets the file system cache flags to enforce hard limits on the minimum and maximum sizes.
    [PoshInternals.FileSystemCacheFlags]$Flags
    )

    Set-Privilege -Privilege "SeIncreaseQuotaPrivilege"
    [PoshInternals.SystemCache]::SetCacheFileSize($Minimum, $Maximum, $Flags)
}





