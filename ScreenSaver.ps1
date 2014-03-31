[Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

[System.WIndows.Forms.Application]::EnableVisualStyles()
[System.WIndows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

function Show-ScreenSaver
{
    $screen = [System.Windows.Forms.Screen]::PrimaryScreen
    
    $screenSaver = New-Object System.Windows.Forms.Form
    $screenSaver.Bounds = $screen.Bounds

    $screenSaver.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None

    $screenSaver.BackColor = [System.Drawing.Color]::FromArgb(17, 114, 169)
    $screenSaver.TopMost = $true

    $screenSaver.add_Load({
            [System.Windows.Forms.Cursor]::Hide()
            $this.TopMost = $true
    })

    $screenSaver.add_MouseClick({
        [System.Windows.Forms.Application]::Exit()
    })
    $screenSaver.add_KeyPress({
        [System.Windows.Forms.Application]::Exit()
    })

    $smiley = New-Object System.Windows.Forms.Label
    $general = New-Object System.Windows.Forms.Label
    $specific = New-Object System.Windows.Forms.Label

    $smiley.Text = ":("
    $general.Text = "Your PC ran into a problem that it couldn't handle, and now it needs to restart."
    $specific.Text = "You can search for the error online: HAL_INITIALIZATION_FAILED"

    $general.AutoSize = $false
    $specific.AutoSize = $false

    $smiley.ForeColor = [System.Drawing.Color]::White
    $general.ForeColor = [System.Drawing.Color]::White
    $specific.ForeColor = [System.Drawing.Color]::White
            
    $smiley.Font = New-Object System.Drawing.Font -ArgumentList "Segoe UI", 100
    $general.Font = New-Object System.Drawing.Font -ArgumentList "Segoe UI", 25
    $specific.Font = New-Object System.Drawing.Font -ArgumentList "Segoe UI", 15

    $Bounds = $screenSaver.Bounds

    $smiley.Size = New-Object System.Drawing.Size -ArgumentList ($Bounds.Right - $Bounds.Left), (($Bounds.Bottom - $Bounds.Top) / 6)
    $smiley.Location = new-object System.Drawing.Point -ArgumentList (($Bounds.Right - $Bounds.Left) / 4), (($Bounds.Bottom - $Bounds.Top) / 3)

    $general.Size = new-object System.Drawing.Size -ArgumentList (($Bounds.Right - $Bounds.Left) / 2), (($Bounds.Bottom - $Bounds.Top) / 8)
    $general.Location = New-Object System.Drawing.Point -ArgumentList (($Bounds.Right - $Bounds.Left) / 4), ($smiley.Location.Y + ($Bounds.Bottom - $Bounds.Top) / 6)

    $specific.Size = new-object System.Drawing.Size -ArgumentList (($Bounds.Right - $Bounds.Left) / 2), (($Bounds.Bottom - $Bounds.Top) / 6)
    $specific.Location = new-object System.Drawing.Point -ArgumentList (($Bounds.Right - $Bounds.Left) / 4), ($general.Location.Y + ($Bounds.Bottom - $Bounds.Top) / 8)
            
    $screenSaver.Controls.Add($smiley);
    $screenSaver.Controls.Add($general);
    $screenSaver.Controls.Add($specific);

    $screenSaver.ShowDialog()
    
}

$sargs = [Environment]::GetCommandLineArgs()
    
if ($sargs.Length -gt 0)
{
    if ($sargs[1].ToLower().Trim() -eq "/s")      #Full-screen mode
    {
        Show-ScreenSaver
    } 
}