<#
Tira um screenshot da tela inteira (monitor primário) e salva em -Out.
Use pra confirmar a view atual do Higgsfield ANTES de confiar em coordenadas fixas
de higgsfield_generate.ps1 / higgsfield_loop.ps1 — o layout desloca ~32px conforme
o banner amarelo do topo estiver visível ou não.
#>
param(
    [Parameter(Mandatory=$true)][string]$Out
)

Add-Type -AssemblyName System.Windows.Forms,System.Drawing
$bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$bmp = New-Object System.Drawing.Bitmap $bounds.Width, $bounds.Height
$graphics = [System.Drawing.Graphics]::FromImage($bmp)
$graphics.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)
$bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
$graphics.Dispose()
$bmp.Dispose()
Write-Output $Out
