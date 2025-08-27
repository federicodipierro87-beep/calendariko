@echo off
setlocal enabledelayedexpansion
title Calendariko - Installazione Semplificata
chcp 65001 >nul

cls
echo.
echo =========================================
echo   CALENDARIKO - INSTALLAZIONE SEMPLICE
echo =========================================
echo.
echo Questa installazione preparera Calendariko
echo con i seguenti passi automatici:
echo.
echo * 1. Controllo/Installazione Node.js
echo * 2. Copia file applicazione
echo * 3. Installazione dipendenze (npm install)
echo * 4. Configurazione ambiente
echo * 5. Creazione script di avvio
echo.
echo NOTA: Database PostgreSQL richiede setup separato
echo       (verra spiegato al termine)
echo.

set /p CONTINUE="Continuare? (S/N): "
if /i not "%CONTINUE%"=="S" (
    echo Installazione annullata.
    pause
    exit /b 0
)

echo.
echo ==========================================
echo            FASE 1: NODE.JS
echo ==========================================

:: Controlla se Node.js è installato
node --version >nul 2>&1
if !errorLevel! equ 0 (
    echo [OK] Node.js trovato:
    node --version
    npm --version
    echo.
    goto :copy_files
) else (
    echo [ERRORE] Node.js non trovato!
    echo.
    goto :install_node
)

:install_node
echo Installazione Node.js automatica in corso...
echo (Questo potrebbe richiedere alcuni minuti)
echo.

:: Download Node.js
echo Download Node.js LTS...
powershell -ExecutionPolicy Bypass -Command "try { Invoke-WebRequest -Uri 'https://nodejs.org/dist/v20.10.0/node-v20.10.0-x64.msi' -OutFile '%TEMP%\node-installer.msi' -UseBasicParsing; Write-Host 'Download OK' } catch { Write-Host 'Download FAILED'; exit 1 }"

if exist "%TEMP%\node-installer.msi" (
    echo [OK] Download completato
    echo.
    echo Installazione Node.js...
    start /wait msiexec /i "%TEMP%\node-installer.msi" /quiet /norestart ADDLOCAL=ALL
    
    echo Attesa completamento installazione...
    timeout /t 15 >nul
    
    :: Aggiorna PATH
    set "PATH=%PATH%;%ProgramFiles%\nodejs"
    
    :: Verifica installazione
    echo Verifica installazione...
    timeout /t 5 >nul
    node --version >nul 2>&1
    if !errorLevel! equ 0 (
        echo [OK] Node.js installato correttamente:
        node --version
        npm --version
    ) else (
        echo [ERRORE] Verifica Node.js fallita
        echo.
        echo SOLUZIONE:
        echo 1. Chiudere questo prompt
        echo 2. Aprire nuovo prompt dei comandi  
        echo 3. Riavviare l'installer
        echo.
        pause
        exit /b 1
    )
    
    del "%TEMP%\node-installer.msi" 2>nul
) else (
    echo [ERRORE] Download Node.js fallito
    echo.
    echo SOLUZIONE MANUALE:
    echo 1. Andare su: https://nodejs.org
    echo 2. Scaricare Node.js LTS
    echo 3. Installare manualmente
    echo 4. Riavviare questo installer
    echo.
    pause
    exit /b 1
)

:copy_files
echo.
echo ==========================================
echo       FASE 2: COPIA FILES
echo ==========================================

:: Crea directory di installazione
if not exist "C:\Calendariko" mkdir "C:\Calendariko"
if not exist "C:\Calendariko\app" mkdir "C:\Calendariko\app"

echo Copia file applicazione in corso...

:: Verifica se siamo nella directory corretta
if not exist "..\package.json" (
    echo [ERRORE] File sorgente non trovati!
    echo.
    echo Directory corrente: !CD!
    echo.
    echo SOLUZIONE:
    echo 1. Assicurarsi di eseguire questo script dalla cartella installer
    echo 2. La struttura dovrebbe essere:
    echo    Calendariko\
    echo    +-- installer\
    echo    ^   +-- Simple-Install-Clean.bat  (questo file)
    echo    +-- package.json
    echo    +-- src\
    echo    +-- altri file...
    echo.
    pause
    exit /b 1
)

echo Copiando file da .. a C:\Calendariko\app ...

:: Usa robocopy se disponibile
where robocopy >nul 2>&1
if !errorLevel! equ 0 (
    echo Usando robocopy...
    robocopy ".." "C:\Calendariko\app" /E /XD node_modules .next .git installer dist /XF *.log *.pid .env.local /NFL /NDL /NJH
    if !errorLevel! leq 7 (
        echo [OK] File copiati con robocopy
    ) else (
        goto :xcopy_fallback
    )
) else (
    goto :xcopy_fallback
)

goto :npm_install

:xcopy_fallback
echo Usando xcopy...
xcopy /E /I /H /Q /Y "..\*" "C:\Calendariko\app\" 2>nul
if !errorLevel! equ 0 (
    echo [OK] File copiati con xcopy
    
    :: Rimuovi directory non necessarie
    if exist "C:\Calendariko\app\node_modules" rmdir /s /q "C:\Calendariko\app\node_modules" 2>nul
    if exist "C:\Calendariko\app\.next" rmdir /s /q "C:\Calendariko\app\.next" 2>nul
    if exist "C:\Calendariko\app\.git" rmdir /s /q "C:\Calendariko\app\.git" 2>nul
    if exist "C:\Calendariko\app\installer" rmdir /s /q "C:\Calendariko\app\installer" 2>nul
) else (
    echo [ERRORE] Copia file fallita
    pause
    exit /b 1
)

:npm_install
echo.
echo ==========================================
echo      FASE 3: DIPENDENZE NPM
echo ==========================================

cd /d "C:\Calendariko\app"

:: Verifica che package.json esista
if not exist "package.json" (
    echo [ERRORE] package.json non trovato!
    echo.
    echo File nella directory:
    dir /b
    echo.
    pause
    exit /b 1
)

echo [OK] package.json trovato
echo.
echo Installazione dipendenze NPM...
echo (Questo puo richiedere 3-8 minuti)
echo Attendere senza premere tasti...
echo.

:: Primo tentativo ottimizzato
echo Esecuzione: npm install --no-audit --no-fund --prefer-offline
npm install --no-audit --no-fund --prefer-offline --loglevel=error

set NPM_EXIT=!errorLevel!
echo NPM exit code: !NPM_EXIT!

if !NPM_EXIT! equ 0 (
    echo.
    echo [OK] Dipendenze NPM installate correttamente
    goto :configuration
)

:: Secondo tentativo se il primo fallisce
echo.
echo [AVVISO] Primo tentativo fallito (Exit: !NPM_EXIT!)
echo Secondo tentativo con cache pulita...
echo.

npm cache clean --force >nul 2>&1
npm install --no-optional --loglevel=warn

set NPM_EXIT2=!errorLevel!

if !NPM_EXIT2! equ 0 (
    echo.
    echo [OK] Installazione riuscita al secondo tentativo
    goto :configuration
)

:: Se entrambi i tentativi falliscono
echo.
echo [ERRORE] Entrambi i tentativi NPM falliti
echo.
echo Informazioni sistema:
echo - Directory: !CD!
echo - Node.js: 
node --version || echo "Node.js non funziona"
echo - NPM: 
npm --version || echo "NPM non funziona"
echo.
echo POSSIBILI CAUSE:
echo 1. Connessione internet instabile
echo 2. Antivirus blocca NPM
echo 3. Spazio disco insufficiente  
echo 4. Registry NPM non raggiungibile
echo.
echo SOLUZIONI:
echo 1. Controllare connessione internet
echo 2. Disabilitare temporaneamente antivirus
echo 3. Liberare spazio disco
echo 4. Provare da rete diversa
echo.
set /p MANUAL="Continuare senza dipendenze installate? (S/N): "
if /i "!MANUAL!" neq "S" (
    pause
    exit /b 1
)

echo [AVVISO] Continuando senza dipendenze
echo [AVVISO] Sara necessario eseguire manualmente: npm install

:configuration
echo.
echo ==========================================
echo     FASE 4: CONFIGURAZIONE
echo ==========================================

echo Creazione file .env.local...

(
echo # Database
echo DATABASE_URL="postgresql://postgres:calendariko123@localhost:5432/calendariko"
echo.
echo # Auth  
echo NEXTAUTH_URL="http://localhost:3000"
echo NEXTAUTH_SECRET="simple-install-secret-2024-!RANDOM!"
echo JWT_SECRET="simple-jwt-secret-2024-!RANDOM!"
echo.
echo # Email ^(configurare se necessario^)
echo SMTP_HOST="smtp.gmail.com"
echo SMTP_PORT=587
echo SMTP_USER=""
echo SMTP_PASS=""
echo.
echo # File Upload
echo UPLOAD_MAX_SIZE=26214400
echo ALLOWED_FILE_TYPES="pdf,jpg,jpeg,png,docx"
echo.
echo # App Config
echo APP_NAME="Calendariko"
echo DEFAULT_TIMEZONE="Europe/Rome"
) > ".env.local"

if exist ".env.local" (
    echo [OK] File di configurazione creato
) else (
    echo [ERRORE] Creazione configurazione fallita
)

echo.
echo ==========================================
echo       FASE 5: SCRIPT AVVIO
echo ==========================================

echo Creazione script di avvio...

:: Script di avvio principale
(
echo @echo off
echo title Calendariko - Sistema Calendario Band
echo.
echo echo ========================================
echo echo    CALENDARIKO - AVVIO APPLICAZIONE  
echo echo ========================================
echo echo.
echo echo Controllo prerequisiti...
echo.
echo :: Verifica Node.js
echo node --version ^>nul 2^>^&1
echo if errorlevel 1 ^(
echo     echo [ERRORE] Node.js non trovato!
echo     echo Installare da: https://nodejs.org
echo     pause
echo     exit
echo ^)
echo.
echo echo [OK] Node.js disponibile
echo echo.
echo echo Controllo PostgreSQL...
echo netstat -an ^| findstr ":5432" ^>nul
echo if errorlevel 1 ^(
echo     echo.
echo     echo [ERRORE] POSTGRESQL NON IN ESECUZIONE!
echo     echo.
echo     echo DOCKER ^(OPZIONE CONSIGLIATA^):
echo     echo.
echo     echo docker run --name calendariko-postgres ^^
echo     echo   -e POSTGRES_PASSWORD=calendariko123 ^^
echo     echo   -e POSTGRES_DB=calendariko ^^
echo     echo   -p 5432:5432 -d postgres:15
echo     echo.
echo     echo INSTALLAZIONE MANUALE:
echo     echo 1. https://postgresql.org
echo     echo 2. Password: calendariko123
echo     echo 3. Creare database: calendariko
echo     echo.
echo     echo DATABASE ESISTENTE:
echo     echo Modificare .env.local con i vostri parametri
echo     echo.
echo     set /p DB_CHOICE="Continuare dopo aver avviato PostgreSQL? (S/N): "
echo     if /i not "%%DB_CHOICE%%"=="S" exit
echo     echo.
echo     netstat -an ^| findstr ":5432" ^>nul
echo     if errorlevel 1 ^(
echo         echo [ERRORE] PostgreSQL ancora non disponibile
echo         pause
echo         exit
echo     ^)
echo ^)
echo.
echo echo [OK] PostgreSQL disponibile
echo echo.
echo cd /d "C:\Calendariko\app"
echo.
echo echo Inizializzazione database...
echo npm run db:generate
echo npm run db:push  
echo npm run db:seed
echo.
echo echo [OK] Database inizializzato
echo echo.
echo echo Avvio applicazione web...
echo echo.
echo echo ^* URL: http://localhost:3000
echo echo ^* Admin: admin@calendariko.com / admin123
echo echo ^* Manager: manager1@example.com / manager123
echo echo ^* Member: member1@example.com / member123
echo echo.
echo echo Apertura browser...
echo timeout /t 3 ^>nul
echo start "" "http://localhost:3000"
echo.
echo echo Avvio server...
echo npm run dev
) > "C:\Calendariko\Avvia-Calendariko.bat"

:: Script di stop
(
echo @echo off
echo title Calendariko - Stop
echo echo Terminazione Calendariko...
echo taskkill /f /im node.exe 2^>nul
echo echo [OK] Servizi arrestati
echo timeout /t 2 ^>nul
) > "C:\Calendariko\Stop-Calendariko.bat"

echo [OK] Script di avvio creati

:: Collegamento desktop
echo Creazione collegamento desktop...
powershell -ExecutionPolicy Bypass -Command "try { $WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%USERPROFILE%\Desktop\Calendariko.lnk'); $Shortcut.TargetPath = 'C:\Calendariko\Avvia-Calendariko.bat'; $Shortcut.WorkingDirectory = 'C:\Calendariko\app'; $Shortcut.Description = 'Avvia Calendariko'; $Shortcut.Save() }" 2>nul

echo [OK] Setup completato

echo.
echo ==========================================
echo        INSTALLAZIONE COMPLETATA!
echo ==========================================
echo.
echo * Calendariko installato in: C:\Calendariko\
echo * Collegamento desktop: Calendariko.lnk
echo * Script configurati e pronti
echo.
echo PROSSIMI PASSI:
echo.
echo 1. AVVIARE POSTGRESQL:
echo    - Docker: comando fornito nello script
echo    - Manuale: https://postgresql.org
echo.
echo 2. AVVIARE CALENDARIKO:
echo    Doppio clic su "Calendariko" sul desktop
echo.
echo 3. ACCESSO APPLICAZIONE:
echo    http://localhost:3000
echo    admin@calendariko.com / admin123
echo.
echo ==========================================
echo.

set /p START_NOW="Aprire la cartella di installazione? (S/N): "
if /i "%START_NOW%"=="S" (
    explorer C:\Calendariko
)

echo.
echo [COMPLETATO] Installazione riuscita!
echo Fare doppio clic su "Calendariko" sul desktop per iniziare
echo.
pause