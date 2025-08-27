# Calendariko - Script di Installazione Automatica
# Versione: 1.0

param(
    [string]$InstallPath = "C:\Calendariko",
    [string]$DatabasePassword = "calendariko123",
    [int]$DatabasePort = 5432,
    [int]$AppPort = 3000,
    [switch]$SkipNodeInstall = $false,
    [switch]$SkipPostgreSQLInstall = $false,
    [switch]$Unattended = $false
)

# Colori per output
$Host.UI.RawUI.WindowTitle = "Calendariko Installer"

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Step {
    param([string]$Message)
    Write-ColorOutput "=> $Message" "Cyan"
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "✓ $Message" "Green"
}

function Write-Error {
    param([string]$Message)
    Write-ColorOutput "✗ $Message" "Red"
}

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput "⚠ $Message" "Yellow"
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-NodeJS {
    Write-Step "Controllo installazione Node.js..."
    
    try {
        $nodeVersion = & node --version 2>$null
        if ($nodeVersion -and $nodeVersion -match "v(\d+)\.(\d+)\.(\d+)") {
            $majorVersion = [int]$matches[1]
            if ($majorVersion -ge 18) {
                Write-Success "Node.js $nodeVersion già installato"
                return $true
            }
        }
    } catch {
        Write-Warning "Node.js non trovato"
    }

    Write-Step "Download e installazione Node.js LTS..."
    
    $nodeUrl = "https://nodejs.org/dist/v20.10.0/node-v20.10.0-x64.msi"
    $nodeInstaller = "$env:TEMP\node-installer.msi"
    
    try {
        Write-Step "Download Node.js..."
        Invoke-WebRequest -Uri $nodeUrl -OutFile $nodeInstaller -UseBasicParsing -TimeoutSec 300
        
        Write-Step "Installazione Node.js in corso..."
        $installArgs = @(
            "/i", $nodeInstaller,
            "/quiet",
            "/norestart",
            "ADDLOCAL=ALL"
        )
        
        $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $installArgs -Wait -PassThru -NoNewWindow
        
        if ($process.ExitCode -eq 0) {
            # Aggiorna PATH per la sessione corrente
            $machinePath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
            $userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
            $env:PATH = $machinePath + ";" + $userPath
            
            # Verifica installazione
            Start-Sleep -Seconds 5
            $nodeVersion = & node --version 2>$null
            if ($nodeVersion) {
                Write-Success "Node.js $nodeVersion installato correttamente"
                Remove-Item $nodeInstaller -Force -ErrorAction SilentlyContinue
                return $true
            } else {
                throw "Verifica installazione Node.js fallita"
            }
        } else {
            throw "Installazione Node.js fallita con codice: $($process.ExitCode)"
        }
    } catch {
        Write-Error "Errore durante l'installazione di Node.js: $_"
        return $false
    }
}

function Install-PostgreSQL {
    Write-Step "Configurazione PostgreSQL portatile..."
    
    $postgresPath = "$InstallPath\postgresql"
    $dataPath = "$InstallPath\data"
    
    # Per semplicità, usiamo una versione portatile più semplice
    # Creiamo una configurazione di base che userà il PostgreSQL di sistema se disponibile
    
    if (-not (Test-Path $postgresPath)) {
        New-Item -ItemType Directory -Path $postgresPath -Force
        Write-Success "Directory PostgreSQL creata"
    }
    
    if (-not (Test-Path $dataPath)) {
        New-Item -ItemType Directory -Path $dataPath -Force
        Write-Success "Directory dati creata"
    }
    
    # Controlliamo se PostgreSQL è già installato nel sistema
    try {
        $psqlVersion = & psql --version 2>$null
        if ($psqlVersion) {
            Write-Success "PostgreSQL già disponibile nel sistema: $psqlVersion"
            return $true
        }
    } catch {
        Write-Warning "PostgreSQL non trovato nel sistema"
    }
    
    # Per ora, saltiamo l'installazione di PostgreSQL e suggeriamo installazione manuale
    Write-Warning "PostgreSQL non disponibile. Installare manualmente da https://postgresql.org"
    Write-Warning "Oppure usare Docker: docker run --name postgres -e POSTGRES_PASSWORD=$DatabasePassword -p ${DatabasePort}:5432 -d postgres:15"
    
    return $true
}

function Install-Application {
    Write-Step "Installazione applicazione Calendariko..."
    
    $appPath = "$InstallPath\app"
    
    # Copia i file dell'applicazione
    if (Test-Path "..\src") {
        Write-Step "Copia file applicazione..."
        
        # Crea directory app se non esiste
        if (-not (Test-Path $appPath)) {
            New-Item -ItemType Directory -Path $appPath -Force
        }
        
        # Copia tutti i file del progetto eccetto node_modules e .next
        $excludeDirs = @("node_modules", ".next", ".git", "installer", "dist")
        
        Get-ChildItem -Path ".." | Where-Object {
            $_.Name -notin $excludeDirs
        } | Copy-Item -Destination $appPath -Recurse -Force
        
        Write-Success "File applicazione copiati"
    } else {
        Write-Error "File sorgente applicazione non trovati"
        return $false
    }
    
    # Installa dipendenze NPM
    Write-Step "Installazione dipendenze NPM..."
    Push-Location $appPath
    
    try {
        $npmProcess = Start-Process -FilePath "npm" -ArgumentList "install", "--silent" -Wait -PassThru -NoNewWindow
        if ($npmProcess.ExitCode -eq 0) {
            Write-Success "Dipendenze NPM installate"
        } else {
            throw "Errore durante npm install (Exit Code: $($npmProcess.ExitCode))"
        }
    } catch {
        Write-Error "Errore durante l'installazione delle dipendenze: $_"
        Pop-Location
        return $false
    } finally {
        Pop-Location
    }
    
    return $true
}

function Create-Configuration {
    Write-Step "Creazione configurazione applicazione..."
    
    $appPath = "$InstallPath\app"
    $envFile = "$appPath\.env.local"
    
    $databaseUrl = "postgresql://postgres:${DatabasePassword}@localhost:${DatabasePort}/calendariko"
    
    $envContent = @"
# Database
DATABASE_URL="$databaseUrl"

# Auth
NEXTAUTH_URL="http://localhost:$AppPort"
NEXTAUTH_SECRET="$((New-Guid).ToString())"
JWT_SECRET="$((New-Guid).ToString())"

# Email (configurare manualmente se necessario)
SMTP_HOST="smtp.gmail.com"
SMTP_PORT=587
SMTP_USER=""
SMTP_PASS=""

# File Upload
UPLOAD_MAX_SIZE=26214400
ALLOWED_FILE_TYPES="pdf,jpg,jpeg,png,docx"

# App Config
APP_NAME="Calendariko"
DEFAULT_TIMEZONE="Europe/Rome"
"@
    
    $envContent | Out-File -FilePath $envFile -Encoding UTF8
    Write-Success "File di configurazione creato: $envFile"
    
    return $true
}

function Initialize-Application {
    Write-Step "Inizializzazione database applicazione..."
    
    $appPath = "$InstallPath\app"
    Push-Location $appPath
    
    try {
        # Genera client Prisma
        Write-Step "Generazione client Prisma..."
        $prismaGenProcess = Start-Process -FilePath "npm" -ArgumentList "run", "db:generate" -Wait -PassThru -NoNewWindow
        
        if ($prismaGenProcess.ExitCode -ne 0) {
            throw "Errore durante la generazione del client Prisma (Exit Code: $($prismaGenProcess.ExitCode))"
        }
        
        # Applica schema database
        Write-Step "Applicazione schema database..."
        $prismaPushProcess = Start-Process -FilePath "npm" -ArgumentList "run", "db:push" -Wait -PassThru -NoNewWindow
        
        if ($prismaPushProcess.ExitCode -ne 0) {
            throw "Errore durante l'applicazione dello schema (Exit Code: $($prismaPushProcess.ExitCode))"
        }
        
        # Popola database con dati demo
        Write-Step "Popolamento database con dati demo..."
        $prismaSeedProcess = Start-Process -FilePath "npm" -ArgumentList "run", "db:seed" -Wait -PassThru -NoNewWindow
        
        if ($prismaSeedProcess.ExitCode -ne 0) {
            throw "Errore durante il seeding del database (Exit Code: $($prismaSeedProcess.ExitCode))"
        }
        
        Write-Success "Database inizializzato correttamente"
        return $true
    } catch {
        Write-Error "Errore durante l'inizializzazione: $_"
        return $false
    } finally {
        Pop-Location
    }
}

function Create-StartupScripts {
    Write-Step "Creazione script di avvio..."
    
    # Script per avviare l'applicazione
    $startAppScript = @"
@echo off
title Calendariko - Applicazione Web

echo Avvio applicazione Calendariko...
cd /d "$InstallPath\app"

echo Avvio applicazione su http://localhost:$AppPort
echo Premere Ctrl+C per fermare l'applicazione
echo.

npm run dev
pause
"@
    
    $startAppScript | Out-File "$InstallPath\Start-Calendariko.bat" -Encoding ASCII
    
    # Script per fermare tutto
    $stopScript = @"
@echo off
title Calendariko - Stop Services

echo Arresto servizi Calendariko...

echo Terminazione applicazione Node.js...
taskkill /f /im node.exe 2>nul

echo Servizi arrestati.
timeout /t 3 >nul
"@
    
    $stopScript | Out-File "$InstallPath\Stop-Calendariko.bat" -Encoding ASCII
    
    # Script di avvio completo
    $startAllScript = @"
@echo off
title Calendariko - Avvio Completo

cd /d "$InstallPath"

echo ================================
echo    CALENDARIKO - AVVIO
echo ================================
echo.

echo Avvio applicazione web...
start "" Start-Calendariko.bat
timeout /t 5 >nul

echo Apertura browser...
start "" "http://localhost:$AppPort"

echo.
echo ================================
echo Calendariko avviato!
echo ================================
echo.
echo URL: http://localhost:$AppPort
echo.
echo Account demo:
echo - Admin: admin@calendariko.com / admin123
echo - Manager: manager1@example.com / manager123
echo - Member: member1@example.com / member123
echo.
echo Per arrestare: Stop-Calendariko.bat
echo.
pause
"@
    
    $startAllScript | Out-File "$InstallPath\Avvia-Calendariko.bat" -Encoding ASCII
    
    Write-Success "Script di avvio creati"
}

function Create-DesktopShortcut {
    Write-Step "Creazione collegamento desktop..."
    
    try {
        $WshShell = New-Object -comObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\Calendariko.lnk")
        $Shortcut.TargetPath = "$InstallPath\Avvia-Calendariko.bat"
        $Shortcut.WorkingDirectory = $InstallPath
        $Shortcut.Description = "Avvia Calendariko - Sistema Gestione Calendario Band"
        $Shortcut.Save()
        
        Write-Success "Collegamento desktop creato"
    } catch {
        Write-Warning "Impossibile creare il collegamento desktop: $_"
    }
}

function Main {
    Clear-Host
    
    $banner = @"
=========================================
      CALENDARIKO INSTALLER v1.0
=========================================
Sistema di gestione calendario per band

Requisiti:
- Windows 10/11
- 2GB spazio libero
- Connessione internet
- PostgreSQL (installare manualmente)

Percorso installazione: $InstallPath
Porta applicazione: $AppPort
========================================="@
    
    Write-ColorOutput $banner "Yellow"
    Write-Host ""
    
    if (-not $Unattended) {
        $continue = Read-Host "Continuare con l'installazione? (S/N)"
        if ($continue -notmatch "^[Ss]$") {
            Write-ColorOutput "Installazione annullata." "Yellow"
            exit 0
        }
    }
    
    # Controllo privilegi amministratore
    if (-not (Test-Administrator)) {
        Write-Error "Questo script richiede privilegi di amministratore."
        Write-ColorOutput "Riavviare PowerShell come amministratore e riprovare." "Yellow"
        if (-not $Unattended) { pause }
        exit 1
    }
    
    Write-Host ""
    Write-Step "Inizio installazione..."
    
    # Crea directory di installazione
    if (-not (Test-Path $InstallPath)) {
        New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
        Write-Success "Directory di installazione creata: $InstallPath"
    }
    
    # 1. Installa Node.js
    if (-not $SkipNodeInstall) {
        if (-not (Install-NodeJS)) {
            Write-Error "Installazione Node.js fallita"
            if (-not $Unattended) { pause }
            exit 1
        }
    }
    
    # 2. Configura PostgreSQL
    if (-not $SkipPostgreSQLInstall) {
        if (-not (Install-PostgreSQL)) {
            Write-Error "Configurazione PostgreSQL fallita"
            if (-not $Unattended) { pause }
            exit 1
        }
    }
    
    # 3. Installa applicazione
    if (-not (Install-Application)) {
        Write-Error "Installazione applicazione fallita"
        if (-not $Unattended) { pause }
        exit 1
    }
    
    # 4. Crea configurazione
    if (-not (Create-Configuration)) {
        Write-Error "Creazione configurazione fallita"
        if (-not $Unattended) { pause }
        exit 1
    }
    
    # 5. Crea script di avvio
    Create-StartupScripts
    Create-DesktopShortcut
    
    Write-Host ""
    $successMessage = @"
=========================================
   INSTALLAZIONE BASE COMPLETATA!
=========================================

Calendariko è stato preparato in: $InstallPath

PASSI SUCCESSIVI NECESSARI:

1. INSTALLARE POSTGRESQL:
   - Scaricare da: https://postgresql.org
   - Installare con password: $DatabasePassword
   - Porta: $DatabasePort

2. CREARE DATABASE:
   psql -U postgres -c "CREATE DATABASE calendariko;"

3. AVVIARE CALENDARIKO:
   Fare doppio clic su "Calendariko" sul desktop

ALTERNATIVE RAPIDE:
- Docker: docker run --name postgres -e POSTGRES_PASSWORD=$DatabasePassword -p ${DatabasePort}:5432 -d postgres:15
- Oppure modificare .env.local per database esistente

URL APPLICAZIONE: http://localhost:$AppPort

ACCOUNT DEMO:
- Admin:   admin@calendariko.com / admin123
- Manager: manager1@example.com / manager123  
- Member:  member1@example.com / member123

Per supporto: https://github.com/calendariko
========================================="@
    
    Write-ColorOutput $successMessage "Green"
    
    if (-not $Unattended) {
        Write-Host ""
        Write-ColorOutput "Installazione terminata. Premere un tasto per uscire..." "Yellow"
        pause
    }
}

# Gestione errori globale
trap {
    Write-Error "Errore durante l'installazione: $_"
    Write-ColorOutput "L'installazione è stata interrotta." "Red"
    if (-not $Unattended) { pause }
    exit 1
}

# Esegui installazione
Main