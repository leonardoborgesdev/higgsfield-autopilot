---
name: higgsfield-browser-automation
description: Automatiza a geração de vídeos no site do Higgsfield (Cinema Studio / Seedance) pelo navegador, colando prompts um a um e clicando em Gerar — sozinho ou em loop de 15 em 15 min pra rodar madrugada/desatendido. Use quando o pedido envolver Higgsfield, Seedance, "gerar vídeo pelo site", "colar prompt e gerar", ou continuar/retomar uma fila de prompts que ficou pela metade.
---

# Higgsfield — automação de geração pelo navegador

Clica e cola no site do Higgsfield (`higgsfield.ai`) via PowerShell (`SetCursorPos` +
`mouse_event` + `SendKeys`), porque o Higgsfield **não tem MCP funcional pra geração
direta** (só OAuth de login; as ferramentas de geração não carregam via `codex mcp` —
ver `[[github-mascot-reacts]]` na memória). Validado no projeto do cavaleiro medieval
(`[[cavaleiro-medieval-higgsfield]]`): 34 prompts gerados, loop noturno rodando sozinho
de 15 em 15 min sem travar.

## Pré-requisito: a página tem que estar na view certa

As coordenadas fixas deste skill (`scripts/higgsfield_generate.ps1`) só funcionam na view
**"My generations"** do Cinema Studio (`higgsfield.ai/generate/all`), com a grade de vídeos
já gerados aparecendo e a caixa de prompt fixada por cima dela, com a imagem de referência
do personagem à esquerda. **Sempre bata um screenshot antes de confiar nas coordenadas** —
o layout desloca inteiro (~32px) dependendo se o banner amarelo "Unlimited NEW SEEDANCE"
está visível no topo ou não, e um clique errado pode cair em "Upgrade" ou em outra aba e
te tirar da página (já aconteceu: clique em (1000,150) pra "focar o navegador" foi parar
na página de Pricing porque o banner tinha sumido).

```powershell
# 1. Screenshot pra confirmar que está na view certa antes de qualquer clique
powershell -File scripts\screenshot.ps1 -Out check.png
# leia o PNG com a ferramenta Read antes de prosseguir
```

Se não estiver na view certa: clique em "My generations" na barra lateral esquerda
(~x=108,y=271 com banner, sem sidebar mudar de posição) e re-tire o screenshot.

## Gerar um prompt

```powershell
powershell -File scripts\higgsfield_generate.ps1 -PromptFile "C:\caminho\promptN_only.txt"
```

O script: clica na caixa de prompt → `Ctrl+A` → `Delete` → copia o texto do arquivo pro
clipboard (`Set-Clipboard`, nunca `SendKeys` com o texto cru — prompt tem aspas, quebras de
linha e caracteres que o SendKeys engole) → `Ctrl+V` → clica em Gerar → tira screenshot de
confirmação. **Sempre leia o screenshot de confirmação** (`Read` na imagem) antes de dizer
que gerou: confira que (a) o texto colado bate com o final do prompt esperado e (b) depois
de clicar Gerar, aparece o spinner de loading numa célula nova no topo-esquerdo da grade.

Guarde cada prompt em um arquivo próprio `promptN_only.txt` (um por número) — mais confiável
que manter um `.txt` gigante com todos e recortar substring, e permite retomar de qualquer
ponto sem reprocessar texto.

## Rodar uma fila inteira (loop desatendido, ex: madrugada)

```powershell
powershell -File scripts\higgsfield_loop.ps1 -PromptDir "C:\caminho\scratchpad" -Order 30,31,32,11,12,13
```

Roda em background (`Start-Process ... -WindowStyle Hidden`) com **15 min entre gerações**
(o site não deixa empilhar gerações mais rápido que isso de forma confiável) e log em
`auto_generate_log.txt` dentro do `PromptDir`. Cada tentativa tem 1 retry automático.

**Isso NÃO sobrevive a desligar/hibernar o notebook.** Foi assim que a fila do cavaleiro
parou no prompt 27 de 34 — o processo simplesmente morreu com a máquina. Antes de deixar
rodando a noite toda, avise o usuário disso e sugira desativar suspensão automática
(`powercfg /change standby-timeout-ac 0`) se for ficar horas sem supervisão.

## Depois que a máquina volta

1. Rode `Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe'"` filtrando o
   `CommandLine` pelo nome do script de loop — confirme se ainda tem processo vivo antes de
   assumir que travou ou duplicou. (Cuidado: o próprio comando de verificação pode aparecer
   na lista de processos powershell.exe rodando — não é uma segunda instância do loop.)
2. Leia o log (`auto_generate_log_overnight.txt` ou equivalente) pra ver até onde chegou.
3. Confira `Downloads\hf_<timestamp>_<uuid>.mp4` — o Higgsfield baixa os vídeos prontos
   sozinho quando a aba recarrega/a sessão do navegador é restaurada, não precisa clicar
   "download" em cada um manualmente.
4. Retome só os prompts que faltaram (o log diz exatamente quais rodaram).

## Onde ficam os prompts do projeto atual

Ver `[[cavaleiro-medieval-higgsfield]]` — os `promptN_only.txt` de 1 a 34 e os scripts desta
sessão ficaram em
`%TEMP%\claude\C--Users-henrique\4e6cf08b-64d2-40ac-b943-d47cf0dc8577\scratchpad\`
(pasta de scratchpad de uma sessão específica do Claude Code — some se o histórico for
limpo; para um próximo projeto, copie os prompts pra uma pasta permanente do projeto).
