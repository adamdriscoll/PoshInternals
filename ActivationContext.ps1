<#
.Synopsis
   Enters a Windows Activation Context. 
.DESCRIPTION
   Enters a Windows Activation Context. This cmdlet accepts an activation manifest
   that allows for registry free COM activation. 
.EXAMPLE
   Enter-ActivationContext -Manifest C:\IE.Manifest
#>
function Enter-ActivationContext
{
    # The manifest to use for registry free COM activation
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $manifest
        )

    End 
    {
        if (-not (Test-Path $Manifest))
        {
            Write-Error "$Manifest does not exist"
            return
        }

        if ($global:ActivationContext  -ne $null)
        {
            Write-Error "Already in an activation context."
            return
        }

        $global:ActivationContext = New-Object PoshInternals.ActivationContext
        $global:ActivationContext.CreateAndActivate($manifest)
    }
}

<#
.Synopsis
   Exits a Windows activation context. 
.DESCRIPTION
   Exits a Windows activation context that was opened by Enter-ActivationContext. 
.EXAMPLE
   Exit-ActivationContext
#>
function Exit-ActivationContext
{
    if ($global:ActivationContext -eq $null)
    {
        Write-Warning "Not currently within an activation context."
        return
    }

    $global:ActivationContext.DeactivateAndFree()
}

