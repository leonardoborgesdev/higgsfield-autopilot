<#
Cola um prompt na caixa do Higgsfield Cinema Studio (view "My generations",
higgsfield.ai/generate/all) e clica em Gerar.

REQUISITO: a aba do navegador já precisa estar aberta nessa view, na frente, com o
prompt box visível igual ao screenshot de referencia deste skill. Confirme com
screenshot.ps1 antes de rodar isso -- coordenadas fixas quebram se o layout mudar
(banner promocional aparece/some, janela em outra resolucao, etc).

Coordenadas calibradas pra janela do navegador maximizada em 1366x768 com o banner
amarelo "Unlimited NEW SEEDANCE" visivel no topo. Ajuste TextareaX/Y e GenerateX/Y
se a resolucao/layout for diferente.
#>
param(
    [Parameter(Mandatory=$true)][string]$PromptFile,
    [string]$LogFile = $null,
    [int]$TextareaX = 700,
    [int]$TextareaY = 590,
    [int]$GenerateX = 1213,
    [int]$GenerateY = 646,
    [string]$ScreenshotOut = $null
)

if (-not (Test-Path $PromptFile)) {
    throw "Prompt file nao encontrado: $PromptFile"
}

Add-Type -AssemblyName System.Windows.Forms,System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class HFClick {
  [DllImport("user32.dll")]
  public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")]
  public static extern void mouse_event(uint dwFlags, uint dx, uint dy, uint dwData, UIntPtr dwExtraInfo);
}
"@

function Click($x, $y) {
    [HFClick]::SetCursorPos($x, $y)
    Start-Sleep -Milliseconds 200
    [HFClick]::mouse_event(0x0002, 0, 0, 0, [UIntPtr]::Zero)
    Start-Sleep -Milliseconds 100
    [HFClick]::mouse_event(0x0004, 0, 0, 0, [UIntPtr]::Zero)
}

function Log($msg) {
    $line = "[$(Get-Date -Format 'HH:mm:ss')] $msg"
    Write-Output $line
    if ($LogFile) { $line | Out-File -Append $LogFile }
}

# click na caixa de prompt, selecionar tudo e apagar
Click $TextareaX $TextareaY
Start-Sleep -Milliseconds 500
[System.Windows.Forms.SendKeys]::SendWait("^a")
Start-Sleep -Milliseconds 300
[System.Windows.Forms.SendKeys]::SendWait("{DEL}")
Start-Sleep -Milliseconds 400

# clipboard em vez de SendKeys com o texto cru -- prompt tem aspas/quebras de linha
# que o SendKeys corrompe
$promptText = Get-Content -Raw $PromptFile
Set-Clipboard -Value $promptText
Start-Sleep -Milliseconds 400
[System.Windows.Forms.SendKeys]::SendWait("^v")
Start-Sleep -Milliseconds 800

# clicar em Gerar
Click $GenerateX $GenerateY
Start-Sleep -Milliseconds 1500

Log "Gerado: $PromptFile"

if ($ScreenshotOut) {
    $bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $bmp = New-Object System.Drawing.Bitmap $bounds.Width, $bounds.Height
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)
    $bmp.Save($ScreenshotOut)
    $g.Dispose()
    $bmp.Dispose()
    Log "Screenshot de confirmacao: $ScreenshotOut"
}
