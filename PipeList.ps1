<#
.Synopsis
    Gets the open pipes on the local system.
.DESCRIPTION
   Gets the open pipes on the local system.
.EXAMPLE
   Get-PipeList
#>
function Get-PipeList
{
    End {
            [System.IO.Directory]::GetFiles("\\.\\pipe\\")
        }
}
