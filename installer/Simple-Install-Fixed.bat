@echo off
setlocal enabledelayedexpansion
title Calendariko - Installazione Semplificata (Fixed)
color 0A

:: Verifica privilegi amministratore
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ATTENZIONE: Privilegi amministratore consigliati per installazione Node.js
    echo.
    echo Se Node.js è già installato, continuare normalmente.
    echo Altrimenti fare clic destro e "Esegui come amministratore"
    echo.
    pause
)

cls
echo.
echo =========================================
echo   CALENDARIKO - INSTALLAZIONE SEMPLICE
echo =========================================
echo.
echo Questa installazione preparerà Calendariko
echo con i seguenti passi automatici:
echo.
echo ✓ 1. Controllo/Installazione Node.js
echo ✓ 2. Copia file applicazione
echo ✓ 3. Installazione dipendenze (npm install)
echo ✓ 4. Configurazione ambiente
echo ✓ 5. Creazione script di avvio
echo.
echo ⚠️  Database PostgreSQL richiede setup separato
echo    (verrà spiegato al termine)
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
if %errorLevel% equ 0 (
    echo ✓ Node.js trovato:
    node --version
    npm --version
    echo.
) else (
    echo ❌ Node.js non trovato!
    echo.
    echo Installazione Node.js automatica in corso...
    echo (Questo potrebbe richiedere alcuni minuti)
    echo.
    
    :: Download Node.js
    echo Download Node.js LTS...
    powershell -command "try { Invoke-WebRequest -Uri 'https://nodejs.org/dist/v20.10.0/node-v20.10.0-x64.msi' -OutFile '%TEMP%\node-installer.msi' -UseBasicParsing } catch { exit 1 }"
    
    if exist "%TEMP%\node-installer.msi" (
        echo ✓ Download completato
        echo.
        echo Installazione Node.js...
        start /wait msiexec /i "%TEMP%\node-installer.msi" /quiet /norestart ADDLOCAL=ALL
        
        :: Attendi installazione
        timeout /t 10 >nul
        
        echo ✓ Node.js installato
        
        :: Aggiorna PATH per la sessione corrente
        call refreshenv 2>nul
        set "PATH=%PATH%;%ProgramFiles%\nodejs"
        
        :: Verifica installazione
        timeout /t 5 >nul
        node --version >nul 2>&1
        if !errorLevel! equ 0 (
            echo ✓ Verifica Node.js completata:
            node --version
            npm --version
        ) else (
            echo ❌ Verifica Node.js fallita
            echo.
            echo SOLUZIONE:
            echo 1. Chiudere questo prompt
            echo 2. Aprire nuovo prompt dei comandi
            echo 3. Riavviare l'installer
            echo.
            pause
            exit /b 1
        )
        
        :: Cleanup
        del "%TEMP%\node-installer.msi" 2>nul
    ) else (
        echo ❌ Download Node.js fallito
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
)

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
    echo ❌ ERRORE: File sorgente non trovati!
    echo.
    echo Directory corrente: %CD%
    echo.
    echo SOLUZIONE:
    echo 1. Assicurarsi di eseguire questo script dalla cartella installer
    echo 2. La struttura dovrebbe essere:
    echo    Calendariko\
    echo    ├── installer\
    echo    │   └── Simple-Install-Fixed.bat  (questo file)
    echo    ├── package.json
    echo    ├── src\
    echo    └── altri file...
    echo.
    pause
    exit /b 1
)

:: Copia tutti i file eccetto alcune cartelle
echo Copiando file...
robocopy ".." "C:\Calendariko\app" /E /XD node_modules .next .git installer dist /XF *.log *.pid .env.local /NFL /NDL /NJH /NJS

if !errorLevel! leq 7 (
    echo ✓ File applicazione copiati in C:\Calendariko\app\
) else (
    echo ❌ Errore durante la copia file
    echo.
    echo Tentativo con xcopy...
    xcopy /E /I /H /Y "..\*" "C:\Calendariko\app\" /EXCLUDE:exclude.txt
    if !errorLevel! equ 0 (
        echo ✓ Copia con xcopy completata
    ) else (
        echo ❌ Errore anche con xcopy
        pause
        exit /b 1
    )
)

echo.
echo ==========================================
echo      FASE 3: DIPENDENZE NPM
echo ==========================================

cd /d "C:\Calendariko\app"

:: Verifica che package.json esista
if not exist "package.json" (
    echo ❌ ERRORE: package.json non trovato!
    echo.
    echo File nella directory:
    dir /b
    echo.
    pause
    exit /b 1
)

echo ✓ package.json trovato
echo.
echo Installazione dipendenze NPM...
echo (Questo può richiedere 3-8 minuti)
echo ⏳ Attendere senza premere tasti...
echo.

:: Primo tentativo
npm install --no-audit --no-fund --prefer-offline --progress=false

set NPM_EXIT=!errorLevel!

if !NPM_EXIT! equ 0 (
    echo.
    echo ✓ Dipendenze NPM installate correttamente
) else (
    echo.
    echo ❌ Primo tentativo fallito (Exit: !NPM_EXIT!)
    echo.
    echo Informazioni di debug:
    echo - Directory: !CD!
    echo - Node.js: 
    node --version 2>nul || echo "❌ Node.js non funziona"
    echo - NPM: 
    npm --version 2>nul || echo "❌ NPM non funziona"
    echo.
    echo Secondo tentativo con cache pulita...
    npm cache clean --force
    npm install --verbose --no-optional
    
    set NPM_EXIT2=!errorLevel!
    
    if !NPM_EXIT2! equ 0 (
        echo.
        echo ✓ Installazione riuscita al secondo tentativo
    ) else (
        echo.
        echo ❌ Anche il secondo tentativo è fallito
        echo.
        echo POSSIBILI CAUSE:
        echo 1. Connessione internet instabile
        echo 2. Antivirus blocca NPM
        echo 3. Spazio disco insufficiente
        echo 4. Proxy aziendale
        echo 5. Registry NPM non raggiungibile
        echo.
        echo SOLUZIONI:
        echo 1. Controllare connessione internet
        echo 2. Disabilitare temporaneamente antivirus
        echo 3. Eseguire: npm config set registry https://registry.npmjs.org/
        echo 4. Provare da rete diversa
        echo.
        set /p MANUAL="Continuare senza dipendenze (installazione manuale richiesta)? (S/N): "
        if /i "!MANUAL!"=="S" (
            echo ⚠️ Continuando senza dipendenze installate
            echo ⚠️ Sarà necessario eseguire manualmente: npm install
        ) else (
            pause
            exit /b 1
        )
    )
)

echo.
echo ==========================================
echo     FASE 4: CONFIGURAZIONE
echo ==========================================

:: Crea file di configurazione
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

echo ✓ File di configurazione creato

echo.
echo ==========================================
echo       FASE 5: SCRIPT AVVIO
echo ==========================================

:: Script di avvio principale con migliore gestione database
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
echo     echo ❌ Node.js non trovato!
echo     echo Installare da: https://nodejs.org
echo     pause
echo     exit
echo ^)
echo.
echo :: Verifica directory
echo if not exist "package.json" ^(
echo     echo ❌ File applicazione non trovati!
echo     echo Directory corrente: %%CD%%
echo     echo Verificare l'installazione
echo     pause  
echo     exit
echo ^)
echo.
echo echo ✓ Node.js OK
echo echo ✓ File applicazione OK
echo echo.
echo echo Controllo PostgreSQL...
echo netstat -an ^| findstr ":5432" ^>nul
echo if errorlevel 1 ^(
echo     echo.
echo     echo ❌ POSTGRESQL NON IN ESECUZIONE!
echo     echo.
echo     echo 🐳 OPZIONE 1 - DOCKER ^(CONSIGLIATA^):
echo     echo.
echo     echo docker run --name calendariko-postgres ^^
echo     echo   -e POSTGRES_PASSWORD=calendariko123 ^^
echo     echo   -e POSTGRES_DB=calendariko ^^
echo     echo   -p 5432:5432 -d postgres:15
echo     echo.
echo     echo 📥 OPZIONE 2 - INSTALLAZIONE MANUALE:
echo     echo   1. https://postgresql.org
echo     echo   2. Password: calendariko123
echo     echo   3. Creare database: calendariko
echo     echo.
echo     echo 🔧 OPZIONE 3 - DATABASE ESISTENTE:
echo     echo   Modificare .env.local con i vostri parametri
echo     echo.
echo     set /p DB_CHOICE="Continuare dopo aver avviato PostgreSQL? (S/N): "
echo     if /i not "%%DB_CHOICE%%"=="S" exit
echo     echo.
echo     echo Nuovo controllo PostgreSQL...
echo     netstat -an ^| findstr ":5432" ^>nul
echo     if errorlevel 1 ^(
echo         echo ❌ PostgreSQL ancora non disponibile
echo         echo Verificare l'avvio del database
echo         pause
echo         exit
echo     ^)
echo ^)
echo.
echo echo ✓ PostgreSQL in esecuzione
echo echo.
echo cd /d "C:\Calendariko\app"
echo.
echo echo Inizializzazione database...
echo npm run db:generate
echo if errorlevel 1 ^(
echo     echo ❌ Errore generazione Prisma client
echo     echo Provare: npm install
echo     pause
echo     exit
echo ^)
echo.
echo npm run db:push
echo if errorlevel 1 ^(
echo     echo ❌ Errore applicazione schema database
echo     echo Verificare connessione PostgreSQL
echo     pause
echo     exit  
echo ^)
echo.
echo npm run db:seed
echo if errorlevel 1 ^(
echo     echo ⚠️ Errore popolamento dati demo ^(non critico^)
echo     timeout /t 3 ^>nul
echo ^)
echo.
echo echo ✓ Database inizializzato
echo echo.
echo echo Avvio applicazione web...
echo echo.
echo echo ✅ URL: http://localhost:3000
echo echo ✅ Admin: admin@calendariko.com / admin123
echo echo ✅ Manager: manager1@example.com / manager123
echo echo ✅ Member: member1@example.com / member123
echo echo.
echo echo 🌐 Apertura browser...
echo timeout /t 3 ^>nul
echo start "" "http://localhost:3000"
echo.
echo echo 🚀 Avvio server sviluppo...
echo npm run dev
) > "C:\Calendariko\Avvia-Calendariko.bat"

:: Script per terminare
(
echo @echo off
echo title Calendariko - Stop
echo echo Terminazione Calendariko...
echo taskkill /f /im node.exe 2^>nul
echo echo ✓ Servizi arrestati
echo timeout /t 2 ^>nul
) > "C:\Calendariko\Stop-Calendariko.bat"

echo ✓ Script di avvio creati

:: Collegamento desktop
echo Creazione collegamento desktop...
powershell -command "try { $WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%USERPROFILE%\Desktop\Calendariko.lnk'); $Shortcut.TargetPath = 'C:\Calendariko\Avvia-Calendariko.bat'; $Shortcut.WorkingDirectory = 'C:\Calendariko\app'; $Shortcut.Description = 'Avvia Calendariko'; $Shortcut.Save(); Write-Host 'Collegamento creato' } catch { Write-Host 'Errore collegamento' }"

echo ✓ Collegamento desktop creato

echo.
echo ==========================================
echo        INSTALLAZIONE COMPLETATA!
echo ==========================================
echo.
echo ✅ Calendariko installato in: C:\Calendariko\
echo ✅ Collegamento desktop: Calendariko.lnk
echo ✅ Script configurati e pronti
echo.
echo 📋 PROSSIMI PASSI:
echo.
echo 1️⃣ AVVIARE POSTGRESQL:
if exist "%PROGRAMFILES%\Docker\Docker\Docker Desktop.exe" (
    echo    🐳 Docker rilevato! Usare il comando Docker fornito
) else (
    echo    🐳 Installare Docker Desktop per facilità
    echo    📥 O installare PostgreSQL manualmente
)
echo.
echo 2️⃣ AVVIARE CALENDARIKO:
echo    Doppio clic su "Calendariko" sul desktop
echo.
echo 📊 ACCESSO:
echo    🌐 http://localhost:3000
echo    👤 admin@calendariko.com / admin123
echo.
echo ==========================================
echo.

set /p START_NOW="Aprire la cartella di installazione? (S/N): "
if /i "%START_NOW%"=="S" (
    explorer C:\Calendariko
)

echo.
echo 🎉 Installazione completata con successo!
echo 🎵 Fare doppio clic su "Calendariko" sul desktop per iniziare
echo.
pause