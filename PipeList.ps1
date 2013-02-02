function Get-PipeList
{
    End {
            [System.IO.Directory]::GetFiles("\\.\\pipe\\")
        }
}
PipeList