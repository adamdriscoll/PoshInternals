$Script:ActivationContexts = @()

<#
.Synopsis
   Creates a Windows Activation Context. 
.DESCRIPTION
   Creates a Windows Activation Context. This cmdlet can optionally open
   the activation context.
.EXAMPLE
   Create-ActivationContext -Manifest E:\IE.EXE.Manifest
.EXAMPLE
   Create-ActivationContext -Open -Manifest E:\IE.EXE.Manifest
#>
function New-ActivationContext 
{
    [CmdletBinding()]
    param(
		# The manifest to use for registry free COM activation
        [Parameter(Mandatory)]
        $manifest,
		[Parameter()]
		#Opens the context.
		[Switch]$Open
        )
		    
	End 
    {
        if (-not (Test-Path $Manifest))
        {
            Write-Error "$Manifest does not exist"
            return
        }

		[IntPtr]$ActivationContext = [IntPtr]::Zero

        $actCtx = New-Object PoshInternals.ACTCTX
        $actCtx.cbSize = [System.Runtime.InteropServices.Marshal]::SizeOf([Type]$actCtx.GetType())
        $actCtx.dwFlags = 0
        $actCtx.lpSource = $manifest
        $actCtx.lpResourceName = $null

        $ActivationContext = [PoshInternals.Kernel32]::CreateActCtx([ref]$actCtx)
        if ($ActivationContext -eq [IntPtr]-1)
        {
            throw new-object System.ComponentModel.Win32Exception
        }

		$ActivationContextObject = @{Handle=$ActivationContext;Cookie=$cookie;Manifest=$Manifest}

		if ($Open)
		{
			Open-ActivationContext -ActivationContext $ActivationContextObject
		}

		[PSCustomObject]$ActivationContextObject
    }
}

<#
.Synopsis
   Opens a Windows Activation Context. 
.DESCRIPTION
   Opens a Windows Activation Context. This cmdlet accepts a context created by
   New-ActivationContext.
.EXAMPLE
   Open-ActivationContext -ActivationContext $Context
#>
function Open-ActivationContext
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline=$true)]
        [PSCustomObject]$ActivationContext
        )

    Process 
    {
		[Int]$Cookie = 0

        if (-not ([PoshInternals.Kernel32]::ActivateActCtx($ActivationContext.Handle, [ref]$Cookie)))
        {
            Write-Error (new-object System.ComponentModel.Win32Exception)
        }

		$ActivationContext.Cookie = $Cookie
    }
}

<#
.Synopsis
   Closes a Windows activation context. 
.DESCRIPTION
   Closes a Windows activation context that was opened by Enter-ActivationContext. 
.EXAMPLE
   Close-ActivationContext
#>
function Close-ActivationContext
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline=$true)]
        [PSCustomObject]$ActivationContext
        )

	Process {
	    [PoshInternals.Kernel32]::DeactivateActCtx(0, $ActivationContext.Cookie) | Out-Null
	}
}

<#
.Synopsis
   Removes an activation context.
.DESCRIPTION
   Removes an activation context that was created by New-ActivationContext. Open-ActivationContext will no longer 
   work for the removed activation context.
.EXAMPLE
   Remove-ActivationContext -ActicationContext $Context
#>
function Remove-ActivationContext 
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline=$true)]
        [PSCustomObject]$ActivationContext
        )

	Process {
		[PoshInternals.Kernel32]::DeactivateActCtx(0, $ActivationContext.Cookie) | Out-Null 
		[PoshInternals.Kernel32]::ReleaseActCtx($ActivationContext.Handle) | Out-Null 
	}
}

