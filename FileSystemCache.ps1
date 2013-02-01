function Get-FileSystemCacheSize
{
    [PSCustomObject]@{MaxFileCacheSize=[PoshInternals.SystemCache]::GetMaxFileCacheSize();MinFileCacheSize=[PoshInternals.SystemCache]::GetMaxFileCacheSize();Flags=[PoshInternals.SystemCache]::GetFlags()}
}

function Set-FileSystemCacheSize
{
    param(
    [uint32]$Minimum,
    [uint32]$Maximum,
    $Flags
    )

    Set-Privilege -Privilege "SeIncreaseQuotaPrivilege"
    [PoshInternals.SystemCache]::SetCacheFileSize($Minimum, $Maximum, $Flags)
}





