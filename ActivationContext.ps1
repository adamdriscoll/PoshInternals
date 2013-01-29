function Enter-ActivationContext
{
    param($manifest)

    $global:ActivationContext = New-Object PoshInternals.ActivationContext
    $global:ActivationContext.CreateAndActivate($manifest)
}


function Exit-ActivationContext
{
    $global:ActivationContext.DeactivateAndFree()
}