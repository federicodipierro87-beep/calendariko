param(
    [switch]$SkipNodeInstall
)

Write-Host ""
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "   CALENDARIKO - INSTALLER AUTOMATICO" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Questo installer installera automaticamente:" -ForegroundColor White
Write-Host "1. Node.js (se necessario)" -ForegroundColor Gray
Write-Host "2. Copia file applicazione" -ForegroundColor Gray
Write-Host "3. Dipendenze NPM" -ForegroundColor Gray
Write-Host "4. Configurazione" -ForegroundColor Gray
Write-Host "5. Script di avvio" -ForegroundColor Gray
Write-Host ""
Write-Host "Database PostgreSQL richiede installazione separata." -ForegroundColor Yellow
Write-Host ""
Read-Host "Premere Enter per continuare"

Write-Host ""
Write-Host "FASE 1: Verifica Node.js" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Gray

try {
    $nodeVersion = node --version 2>$null
    if ($nodeVersion -and !$SkipNodeInstall) {
        Write-Host "Node.js trovato: $nodeVersion" -ForegroundColor Green
        $npmVersion = npm --version 2>$null
        Write-Host "NPM versione: $npmVersion" -ForegroundColor Green
    } elseif (!$nodeVersion) {
        Write-Host "Node.js non trovato. Installazione in corso..." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Download Node.js..." -ForegroundColor White
        
        $nodeMsiUrl = "https://nodejs.org/dist/v20.10.0/node-v20.10.0-x64.msi"
        $nodeMsiPath = "$env:TEMP\node-calendariko.msi"
        
        try {
            Invoke-WebRequest -Uri $nodeMsiUrl -OutFile $nodeMsiPath -UseBasicParsing
            Write-Host "Download completato" -ForegroundColor Green
        } catch {
            Write-Host "Errore download. Installare manualmente da nodejs.org" -ForegroundColor Red
            Read-Host "Premere Enter per uscire"
            exit 1
        }
        
        Write-Host "Installazione Node.js..." -ForegroundColor White
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$nodeMsiPath`" /quiet /norestart" -Wait
        
        Write-Host "Pulizia file temporanei..." -ForegroundColor White
        Remove-Item $nodeMsiPath -Force -ErrorAction SilentlyContinue
        
        Write-Host "Verifica installazione..." -ForegroundColor White
        Start-Sleep -Seconds 5
        
        # Refresh PATH
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")
        
        try {
            $nodeVersion = node --version 2>$null
            if ($nodeVersion) {
                Write-Host "Node.js installato correttamente: $nodeVersion" -ForegroundColor Green
            } else {
                throw "Node.js not found after installation"
            }
        } catch {
            Write-Host "Errore installazione Node.js" -ForegroundColor Red
            Write-Host "Riavviare il computer e riprovare" -ForegroundColor Yellow
            Read-Host "Premere Enter per uscire"
            exit 1
        }
    }
} catch {
    Write-Host "Errore durante la verifica di Node.js: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "FASE 2: Copia file applicazione" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Gray

$destPath = "C:\Calendariko\app"

if (!(Test-Path "C:\Calendariko")) {
    New-Item -ItemType Directory -Path "C:\Calendariko" -Force | Out-Null
}
if (!(Test-Path $destPath)) {
    New-Item -ItemType Directory -Path $destPath -Force | Out-Null
}

Write-Host "Copia in corso..." -ForegroundColor White

if (!(Test-Path "package.json")) {
    Write-Host "Errore: package.json non trovato nella directory corrente" -ForegroundColor Red
    Write-Host "Eseguire questo script dalla directory principale di Calendariko" -ForegroundColor Yellow
    Read-Host "Premere Enter per uscire"
    exit 1
}

# Copy files
try {
    $excludeItems = @("node_modules", ".next", ".git", "*.ps1", "*.bat")
    Get-ChildItem -Path . | Where-Object { 
        $item = $_
        !($excludeItems | Where-Object { $item.Name -like $_ })
    } | Copy-Item -Destination $destPath -Recurse -Force
    
    Write-Host "File copiati in $destPath" -ForegroundColor Green
} catch {
    Write-Host "Errore durante la copia: $_" -ForegroundColor Red
    Read-Host "Premere Enter per uscire"
    exit 1
}

Write-Host ""
Write-Host "FASE 3: Installazione dipendenze NPM" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Gray

Set-Location $destPath
Write-Host "Directory corrente: $PWD" -ForegroundColor White
Write-Host ""
Write-Host "Installazione in corso..." -ForegroundColor White
Write-Host "(Attendere 3-5 minuti senza interrompere)" -ForegroundColor Yellow
Write-Host ""

try {
    $process = Start-Process -FilePath "npm" -ArgumentList "install" -Wait -PassThru -NoNewWindow
    if ($process.ExitCode -eq 0) {
        Write-Host "Dipendenze installate con successo" -ForegroundColor Green
    } else {
        throw "NPM install failed with exit code $($process.ExitCode)"
    }
} catch {
    Write-Host ""
    Write-Host "Errore durante npm install: $_" -ForegroundColor Red
    Write-Host "Riprovare manualmente con: cd $destPath && npm install" -ForegroundColor Yellow
    Read-Host "Premere Enter per continuare comunque"
}

Write-Host ""
Write-Host "FASE 4: Configurazione" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Gray

Write-Host "Creazione file .env.local..." -ForegroundColor White

$envContent = @"
DATABASE_URL="postgresql://postgres:calendariko123@localhost:5432/calendariko"
NEXTAUTH_URL="http://localhost:3000"
NEXTAUTH_SECRET="installer-secret-$(Get-Random)"
JWT_SECRET="installer-jwt-$(Get-Random)"
APP_NAME="Calendariko"
DEFAULT_TIMEZONE="Europe/Rome"
"@

$envContent | Out-File -FilePath ".env.local" -Encoding UTF8
Write-Host "File configurazione creato" -ForegroundColor Green

Write-Host ""
Write-Host "FASE 5: Script di avvio" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Gray

Write-Host "Creazione script avvio..." -ForegroundColor White

# Create startup script
$startupScript = @"
@echo off
title Calendariko

echo.
echo Controllo PostgreSQL...
netstat -an | findstr ":5432" >nul
if errorlevel 1 (
    echo.
    echo PostgreSQL non in esecuzione!
    echo.
    echo DOCKER:
    echo docker run --name postgres-cal ^^
    echo   -e POSTGRES_PASSWORD=calendariko123 ^^
    echo   -e POSTGRES_DB=calendariko ^^
    echo   -p 5432:5432 -d postgres:15
    echo.
    echo MANUALE: https://postgresql.org
    echo Password: calendariko123
    echo Database: calendariko
    echo.
    pause
    exit
)

cd /d "$destPath"

echo.
echo Inizializzazione database...
call npm run db:generate
call npm run db:push
call npm run db:seed

echo.
echo Database pronto
echo.
echo Avvio applicazione...
echo URL: http://localhost:3000
echo Admin: admin@calendariko.com / admin123
echo.
start "" "http://localhost:3000"
timeout /t 3 >nul
npm run dev
"@

$startupScript | Out-File -FilePath "C:\Calendariko\Avvia-Calendariko.bat" -Encoding ASCII

# Create stop script
$stopScript = @"
@echo off
echo Arresto Calendariko...
taskkill /f /im node.exe 2>nul
echo Arrestato
timeout /t 2 >nul
"@

$stopScript | Out-File -FilePath "C:\Calendariko\Stop-Calendariko.bat" -Encoding ASCII

Write-Host "Script creati" -ForegroundColor Green

# Create desktop shortcut
Write-Host "Creazione collegamento desktop..." -ForegroundColor White
try {
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\Calendariko.lnk")
    $Shortcut.TargetPath = "C:\Calendariko\Avvia-Calendariko.bat"
    $Shortcut.Save()
    Write-Host "Collegamento desktop creato" -ForegroundColor Green
} catch {
    Write-Host "Avviso: impossibile creare collegamento desktop" -ForegroundColor Yellow
}

Set-Location $PSScriptRoot

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "        INSTALLAZIONE COMPLETATA" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Calendariko installato in: C:\Calendariko\" -ForegroundColor Green
Write-Host ""
Write-Host "PROSSIMI PASSI:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Installare PostgreSQL:" -ForegroundColor White
Write-Host "   - Docker: usare comando nello script" -ForegroundColor Gray
Write-Host "   - Manuale: https://postgresql.org" -ForegroundColor Gray
Write-Host "   - Password: calendariko123" -ForegroundColor Gray
Write-Host "   - Database: calendariko" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Avviare Calendariko:" -ForegroundColor White
Write-Host "   Doppio clic su 'Calendariko' sul desktop" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Aprire browser:" -ForegroundColor White
Write-Host "   http://localhost:3000" -ForegroundColor Gray
Write-Host "   Login: admin@calendariko.com / admin123" -ForegroundColor Gray
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan

Read-Host "Premere Enter per uscire"