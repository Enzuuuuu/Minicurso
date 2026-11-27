param(
    [switch]$Parar,
    [switch]$SemNavegador,
    [switch]$NovaInstancia,
    [string]$Email = "",
    [int]$Porta = 5678,
    [string]$NomeContainer = "n8n-minicurso",
    [string]$Volume = "n8n_minicurso_data",
    [string]$ContainerExistente = "n8n",
    [string]$VolumeExistente = "n8n_data",
    [string]$Imagem = "docker.n8n.io/n8nio/n8n"
)

$ErrorActionPreference = "Stop"
$Raiz = Split-Path -Parent $MyInvocation.MyCommand.Path
$DiretorioLogs = Join-Path $Raiz ".logs"
$ArquivoUrl = Join-Path $Raiz "url-n8n.txt"
$ArquivoPid = Join-Path $DiretorioLogs "cloudflared.pid"

function Escrever {
    param([string]$Texto, [string]$Cor = "Gray")
    Write-Host $Texto -ForegroundColor $Cor
}

function LerLog {
    param([string]$Caminho)
    if (-not (Test-Path $Caminho)) { return "" }
    try {
        $stream = [System.IO.File]::Open($Caminho, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
        try {
            $leitor = New-Object System.IO.StreamReader($stream)
            try { return $leitor.ReadToEnd() } finally { $leitor.Dispose() }
        } finally { $stream.Dispose() }
    } catch { return "" }
}

function AtualizarPath {
    $maquina = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $usuario = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$maquina;$usuario"
}

function DockerDisponivel {
    try { docker info 2>&1 | Out-Null } catch {}
    return $LASTEXITCODE
}

function ContainerExiste {
    param([string]$Nome)
    try { docker container inspect $Nome 2>&1 | Out-Null } catch {}
    return $LASTEXITCODE
}

function EscolherPorta {
    param([int]$Inicial)
    $candidata = $Inicial
    for ($i = 0; $i -lt 20; $i++) {
        $ocupada = Get-NetTCPConnection -LocalPort $candidata -State Listen -ErrorAction SilentlyContinue
        if (-not $ocupada) { return $candidata }
        $candidata++
    }
    throw "Nenhuma porta livre encontrada a partir de $Inicial."
}

function Encerrar {
    Escrever "Encerrando o tunel..." "Yellow"
    ContainerExiste $NomeContainer | Out-Null
    if ($LASTEXITCODE -eq 0) {
        docker rm -f $NomeContainer | Out-Null
        Escrever "Container removido: $NomeContainer" "Gray"
    }
    if (Test-Path $ArquivoPid) {
        $conteudo = Get-Content $ArquivoPid -Raw
        if ($conteudo -match '^\s*(\d+)\s*$') {
            $processo = Get-Process -Id ([int]$Matches[1]) -ErrorAction SilentlyContinue
            if ($processo -and $processo.ProcessName -like "cloudflared*") {
                Stop-Process -Id $processo.Id -Force
                Escrever "Tunel encerrado." "Gray"
            }
        }
        Remove-Item $ArquivoPid -Force -ErrorAction SilentlyContinue
    }
    Remove-Item $ArquivoUrl -Force -ErrorAction SilentlyContinue
    Escrever "Volumes preservados: $VolumeExistente, $Volume" "Green"
}

if ($Parar) {
    Encerrar
    return
}

Escrever "Verificando Docker..." "Cyan"
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "Docker nao encontrado. Instale o Docker Desktop."
}

DockerDisponivel | Out-Null
if ($LASTEXITCODE -ne 0) {
    $dockerDesktop = Join-Path $env:LOCALAPPDATA "Programs\Docker\Docker\Docker Desktop.exe"
    if (Test-Path $dockerDesktop) {
        Escrever "Iniciando Docker Desktop..." "Yellow"
        Start-Process -FilePath $dockerDesktop
        for ($i = 0; $i -lt 45; $i++) {
            Start-Sleep -Seconds 2
            DockerDisponivel | Out-Null
            if ($LASTEXITCODE -eq 0) { break }
        }
    }
}
DockerDisponivel | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "Docker nao iniciou. Abra o Docker Desktop manualmente e rode o script novamente."
}

Escrever "Verificando cloudflared..." "Cyan"
$cloudflared = (Get-Command cloudflared -ErrorAction SilentlyContinue).Source
if (-not $cloudflared) {
    AtualizarPath
    $cloudflared = (Get-Command cloudflared -ErrorAction SilentlyContinue).Source
}
if (-not $cloudflared -and (Get-Command winget -ErrorAction SilentlyContinue)) {
    Escrever "Instalando cloudflared..." "Yellow"
    winget install --id Cloudflare.cloudflared -e --accept-source-agreements --accept-package-agreements | Out-Null
    AtualizarPath
    $cloudflared = (Get-Command cloudflared -ErrorAction SilentlyContinue).Source
}
if (-not $cloudflared) {
    foreach ($caminho in @("C:\Program Files (x86)\cloudflared\cloudflared.exe", "C:\Program Files\cloudflared\cloudflared.exe")) {
        if (Test-Path $caminho) { $cloudflared = $caminho; break }
    }
}
if (-not $cloudflared) {
    throw "cloudflared nao encontrado. Instale manualmente: winget install Cloudflare.cloudflared"
}

New-Item -ItemType Directory -Path $DiretorioLogs -Force | Out-Null
$logSaida = Join-Path $DiretorioLogs "cloudflared.out.log"
$logErro = Join-Path $DiretorioLogs "cloudflared.err.log"
Remove-Item $logSaida, $logErro -Force -ErrorAction SilentlyContinue

$argumentos = @("tunnel", "--url", "http://localhost:$Porta")
if ($Email) { $argumentos += @("--allowed-mail", $Email) }

Escrever "Abrindo tunel..." "Cyan"
$processoTunel = Start-Process -FilePath $cloudflared -ArgumentList $argumentos -PassThru -WindowStyle Hidden -RedirectStandardOutput $logSaida -RedirectStandardError $logErro
$processoTunel.Id | Set-Content $ArquivoPid -Force

$url = $null
for ($i = 0; $i -lt 60; $i++) {
    $conteudo = (LerLog $logSaida) + "`n" + (LerLog $logErro)
    $correspondencia = [regex]::Match($conteudo, "https://[a-z0-9-]+\.trycloudflare\.com")
    if ($correspondencia.Success) {
        $url = $correspondencia.Value
        break
    }
    if ($processoTunel.HasExited) { break }
    Start-Sleep -Milliseconds 1000
}

if (-not $url) {
    Stop-Process -Id $processoTunel.Id -Force -ErrorAction SilentlyContinue
    $final = ((LerLog $logErro) -split "`n" | Select-Object -Last 12) -join "`n"
    throw "Nao consegui capturar a URL do tunel.`n$final"
}

$hostTunel = ([Uri]$url).Host

$alvo = $NomeContainer
$volumeUsado = $Volume

if (-not $NovaInstancia) {
    ContainerExiste $ContainerExistente | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $alvo = $ContainerExistente
        $volumeUsado = $VolumeExistente
        Escrever "Reaproveitando '$alvo' com o volume '$volumeUsado'..." "Cyan"
        docker rm -f $alvo | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Nao consegui reiniciar o container '$alvo'."
        }
    } else {
        Escrever "Container '$ContainerExistente' nao encontrado. Criando '$NomeContainer'." "Yellow"
    }
} else {
    Escrever "Criando instancia isolada '$NomeContainer'." "Cyan"
}

$portaHost = EscolherPorta $Porta

Escrever "Subindo o n8n..." "Cyan"
$portaMapeada = "127.0.0.1:{0}:5678" -f $portaHost
docker run -d --name $alvo --restart unless-stopped `
    -p $portaMapeada `
    -v "${volumeUsado}:/home/node/.n8n" `
    -e "N8N_PROTOCOL=https" `
    -e "N8N_HOST=$hostTunel" `
    -e "N8N_WEBHOOK_URL=$url/" `
    -e "WEBHOOK_URL=$url/" `
    -e "N8N_PROXY_HOPS=1" `
    -e "GENERIC_TIMEZONE=America/Sao_Paulo" `
    -e "TZ=America/Sao_Paulo" `
    $Imagem | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "Falha ao iniciar o container '$alvo'."
}

$saudavel = $false
for ($i = 0; $i -lt 60; $i++) {
    try {
        $resposta = Invoke-WebRequest -Uri "http://localhost:$portaHost/healthz" -UseBasicParsing -TimeoutSec 2
        if ($resposta.StatusCode -eq 200) { $saudavel = $true; break }
    } catch {
        Start-Sleep -Seconds 1
    }
}
if (-not $saudavel) {
    Escrever "O n8n esta subindo, mas ainda nao respondeu ao healthz." "Yellow"
}

$url | Set-Content $ArquivoUrl -Force
try { Set-Clipboard -Value $url } catch {}

Escrever ""
Escrever "======================================================" "Green"
Escrever "URL do n8n: $url" "Green"
Escrever "======================================================" "Green"
Escrever "Container: $alvo | Volume: $volumeUsado | Porta local: $portaHost" "Gray"
Escrever "URL copiada para a area de transferencia e salva em $ArquivoUrl" "Gray"
Escrever "Se o container existente foi reaproveitado, -Parar encerra so o tunel." "Yellow"
if ($Email) {
    Escrever "Aviso: com --allowed-mail, webhooks de servicos externos nao autenticam." "Yellow"
}
Escrever "Para encerrar: .\iniciar-n8n.ps1 -Parar" "Gray"

if (-not $SemNavegador) {
    Start-Process $url
}
