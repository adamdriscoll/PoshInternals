<#
.Synopsis
    Sends a message of a named pipe.
.DESCRIPTION
    Sends a message of a named pipe.This named pipe can exist locally or on a remote machine. By default,
    this cmdlet sends the message using Unicode encoding.
.EXAMPLE
   Send-NamedPipeMessage -PipeName "DrainPipe" -ComputerName "domaincontroller" -Message "Screw you!"
.EXAMPLE
   Send-NamedPipeMessage -PipeName "SewerPipe" -Message "Hello, Pipe!"
#>
function Send-NamedPipeMessage
{
    param(
    # The named pipe to send the message on.
    [String]$PipeName,
    # The computer the named pipe exists on.
    [String]$ComputerName=".",
    # The message to send the named pipe on.
    [string]$Message,
    # The type of encoding to encode the string with
    [System.Text.Encoding]$Encoding = [System.Text.Encoding]::Unicode,
    # The number of milliseconds before the connection times out
    [int]$ConnectTimeout = 5000
    )

    $stream = New-Object -TypeName System.IO.Pipes.NamedPipeClientStream -ArgumentList $ComputerName,$PipeName,([System.IO.Pipes.PipeDirection]::Out), ([System.IO.Pipes.PipeOptions]::None),([System.Security.Principal.TokenImpersonationLevel]::Impersonation)
    $stream.Connect($ConnectTimeout)

    $bRequest = $Encoding.GetBytes($Message)
    $cbRequest = $bRequest.Length; 
 
    $stream.Write($bRequest, 0, $cbRequest); 

    $stream.Dispose()
}
