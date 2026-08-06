<#
Roda uma fila de prompts no Higgsfield sozinho, de 15 em 15 min, em background.
Cada prompt precisa estar em PromptDir\prompt<N>_only.txt.

Uso tipico (dispara e esquece, sobrevive ao fechamento do terminal que chamou):
  Start-Process powershell -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File', `
    'higgsfield_loop.ps1','-PromptDir','C:\projeto\scratchpad','-Order','30,31,32,11,12' `
    -WindowStyle Hidden

NAO sobrevive a desligar/hibernar a maquina -- o processo morre junto. Antes de deixar
rodando desatendido por horas, considere `powercfg /change standby-timeout-ac 0`.
#>
param(
    [Parameter(Mandatory=$true)][string]$PromptDir,
    [Parameter(Mandatory=$true)][int[]]$Order,
    [int]$IntervalSeconds = 900,
    [int]$TextareaX = 700,
    [int]$TextareaY = 590,
    [int]$GenerateX = 1213,
    [int]$GenerateY = 646,
    [string]$LogFile = $null,
    [switch]$SkipFirstWait
)

if (-not $LogFile) { $LogFile = Join-Path $PromptDir "auto_generate_log.txt" }

Add-Type -AssemblyName System.Windows.Forms,System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class HFLoopClick {
  [DllImport("user32.dll")]
  public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")]
  public static extern void mouse_event(uint dwFlags, uint dx, uint dy, uint dwData, UIntPtr dwExtraInfo);
}
"@

function Click($x, $y) {
    [HFLoopClick]::SetCursorPos($x, $y)
    Start-Sleep -Milliseconds 200
    [HFLoopClick]::mouse_event(0x0002, 0, 0, 0, [UIntPtr]::Zero)
    Start-Sleep -Milliseconds 100
    [HFLoopClick]::mouse_event(0x0004, 0, 0, 0, [UIntPtr]::Zero)
}

function Log($msg) {
    "[$(Get-Date -Format 'HH:mm:ss')] $msg" | Out-File -Append $LogFile
}

Log "Loop iniciado. Ordem: $($Order -join ', '). Intervalo: ${IntervalSeconds}s."

$first = $true
foreach ($n in $Order) {
    if (-not ($first -and $SkipFirstWait)) {
        Start-Sleep -Seconds $IntervalSeconds
    }
    $first = $false

    $promptFile = Join-Path $PromptDir "prompt${n}_only.txt"
    if (-not (Test-Path $promptFile)) {
        Log "Prompt $n nao encontrado ($promptFile), pulando."
        continue
    }

    $success = $false
    $attempt = 0
    while (-not $success -and $attempt -lt 2) {
        $attempt++
        try {
            Click $TextareaX $TextareaY
            Start-Sleep -Milliseconds 400

            [System.Windows.Forms.SendKeys]::SendWait("^a")
            Start-Sleep -Milliseconds 200
            [System.Windows.Forms.SendKeys]::SendWait("{DEL}")
            Start-Sleep -Milliseconds 300

            $promptText = Get-Content -Raw $promptFile
            Set-Clipboard -Value $promptText
            Start-Sleep -Milliseconds 300
            [System.Windows.Forms.SendKeys]::SendWait("^v")
            Start-Sleep -Milliseconds 700

            Click $GenerateX $GenerateY
            Start-Sleep -Milliseconds 1500

            Log "Gerado prompt $n (tentativa $attempt)."
            $success = $true
        } catch {
            Log "ERRO no prompt $n tentativa ${attempt}: $_"
            Start-Sleep -Seconds 5
        }
    }

    $bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $bmp = New-Object System.Drawing.Bitmap $bounds.Width, $bounds.Height
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)
    $bmp.Save((Join-Path $PromptDir "auto_screen_after_prompt$n.png"))
    $g.Dispose()
    $bmp.Dispose()
}

Log "Loop finalizado. Prompts processados: $($Order -join ', ')."
