function Send-NamedPipeMessage
{
    param(
    [String]$PipeName,
    [String]$ComputerName=".",
    [string]$Message
    )

    $stream = New-Object -TypeName System.IO.Pipes.NamedPipeClientStream -ArgumentList $ComputerName,$PipeName,([System.IO.Pipes.PipeDirection]::InOut), ([System.IO.Pipes.PipeOptions]::None),([System.Security.Principal.TokenImpersonationLevel]::Impersonation)
    $stream.Connect(5000)

    
    $bRequest = [System.Text.Encoding]::Unicode.GetBytes($Message)
    $cbRequest = $bRequest.Length; 
 
 
    $stream.Write($bRequest, 0, $cbRequest); 

    $stream.Dispose()
}
