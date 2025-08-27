@echo off
setlocal enabledelayedexpansion
title Calendariko - Installazione

cls
echo.
echo =========================================
echo   CALENDARIKO - INSTALLAZIONE SEMPLICE
echo =========================================
echo.
echo Questa installazione preparera Calendariko
echo con i seguenti passi automatici:
echo.
echo 1. Controllo/Installazione Node.js
echo 2. Copia file applicazione
echo 3. Installazione dipendenze npm install
echo 4. Configurazione ambiente
echo 5. Creazione script di avvio
echo.
echo NOTA: Database PostgreSQL richiede setup separato
echo       verra spiegato al termine
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

node --version >nul 2>&1
if %errorLevel% equ 0 (
    echo OK - Node.js trovato:
    node --version
    npm --version
    echo.
) else (
    echo ERRORE - Node.js non trovato
    echo.
    echo Installazione Node.js automatica in corso...
    echo Questo potrebbe richiedere alcuni minuti
    echo.
    
    echo Download Node.js LTS...
    powershell -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri 'https://nodejs.org/dist/v20.10.0/node-v20.10.0-x64.msi' -OutFile '%TEMP%\node-installer.msi' -UseBasicParsing"
    
    if exist "%TEMP%\node-installer.msi" (
        echo OK - Download completato
        echo.
        echo Installazione Node.js...
        start /wait msiexec /i "%TEMP%\node-installer.msi" /quiet /norestart ADDLOCAL=ALL
        
        echo Attesa completamento installazione...
        timeout /t 15 >nul
        
        set "PATH=%PATH%;%ProgramFiles%\nodejs"
        
        echo Verifica installazione...
        timeout /t 5 >nul
        node --version >nul 2>&1
        if !errorLevel! equ 0 (
            echo OK - Node.js installato:
            node --version
            npm --version
        ) else (
            echo ERRORE - Verifica Node.js fallita
            echo.
            echo SOLUZIONE:
            echo 1. Chiudere questo prompt
            echo 2. Aprire nuovo prompt dei comandi  
            echo 3. Riavviare installer
            echo.
            pause
            exit /b 1
        )
        
        del "%TEMP%\node-installer.msi" 2>nul
    ) else (
        echo ERRORE - Download Node.js fallito
        echo.
        echo SOLUZIONE MANUALE:
        echo 1. Andare su https://nodejs.org
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

if not exist "C:\Calendariko" mkdir "C:\Calendariko"
if not exist "C:\Calendariko\app" mkdir "C:\Calendariko\app"

echo Copia file applicazione in corso...

if not exist "..\package.json" (
    echo ERRORE - File sorgente non trovati
    echo.
    echo Directory corrente: %CD%
    echo.
    echo SOLUZIONE:
    echo Assicurarsi di eseguire questo script dalla cartella installer
    echo.
    pause
    exit /b 1
)

echo Copiando file...

where robocopy >nul 2>&1
if %errorLevel% equ 0 (
    echo Usando robocopy...
    robocopy ".." "C:\Calendariko\app" /E /XD node_modules .next .git installer dist /XF *.log *.pid .env.local /NFL /NDL /NJH
    if !errorLevel! leq 7 (
        echo OK - File copiati
    ) else (
        goto xcopy_method
    )
) else (
    :xcopy_method
    echo Usando xcopy...
    xcopy /E /I /H /Q /Y "..\*" "C:\Calendariko\app\" 2>nul
    if !errorLevel! equ 0 (
        echo OK - File copiati
        
        if exist "C:\Calendariko\app\node_modules" rmdir /s /q "C:\Calendariko\app\node_modules" 2>nul
        if exist "C:\Calendariko\app\.next" rmdir /s /q "C:\Calendariko\app\.next" 2>nul
        if exist "C:\Calendariko\app\.git" rmdir /s /q "C:\Calendariko\app\.git" 2>nul
        if exist "C:\Calendariko\app\installer" rmdir /s /q "C:\Calendariko\app\installer" 2>nul
    ) else (
        echo ERRORE - Copia file fallita
        pause
        exit /b 1
    )
)

echo.
echo ==========================================
echo      FASE 3: DIPENDENZE NPM
echo ==========================================

cd /d "C:\Calendariko\app"

if not exist "package.json" (
    echo ERRORE - package.json non trovato
    echo.
    echo File nella directory:
    dir /b
    echo.
    pause
    exit /b 1
)

echo OK - package.json trovato
echo.
echo Installazione dipendenze NPM...
echo Questo puo richiedere 3-8 minuti
echo Attendere senza premere tasti...
echo.

echo Esecuzione npm install...
npm install --no-audit --no-fund --prefer-offline --loglevel=error

set NPM_EXIT=%errorLevel%
echo NPM exit code: %NPM_EXIT%

if %NPM_EXIT% equ 0 (
    echo.
    echo OK - Dipendenze NPM installate
) else (
    echo.
    echo AVVISO - Primo tentativo fallito
    echo Secondo tentativo con cache pulita...
    echo.
    
    npm cache clean --force >nul 2>&1
    npm install --no-optional --loglevel=warn
    
    set NPM_EXIT2=%errorLevel%
    
    if !NPM_EXIT2! equ 0 (
        echo.
        echo OK - Installazione riuscita al secondo tentativo
    ) else (
        echo.
        echo ERRORE - Entrambi i tentativi NPM falliti
        echo.
        echo Informazioni sistema:
        echo Directory: %CD%
        node --version || echo "Node.js non funziona"
        npm --version || echo "NPM non funziona"
        echo.
        echo POSSIBILI CAUSE:
        echo 1. Connessione internet instabile
        echo 2. Antivirus blocca NPM
        echo 3. Spazio disco insufficiente  
        echo 4. Registry NPM non raggiungibile
        echo.
        set /p MANUAL="Continuare senza dipendenze installate? (S/N): "
        if /i "!MANUAL!" neq "S" (
            pause
            exit /b 1
        )
        echo AVVISO - Continuando senza dipendenze
        echo AVVISO - Sara necessario eseguire manualmente npm install
    )
)

echo.
echo ==========================================
echo     FASE 4: CONFIGURAZIONE
echo ==========================================

echo Creazione file .env.local...

echo # Database> .env.local
echo DATABASE_URL="postgresql://postgres:calendariko123@localhost:5432/calendariko">> .env.local
echo.>> .env.local
echo # Auth>> .env.local  
echo NEXTAUTH_URL="http://localhost:3000">> .env.local
echo NEXTAUTH_SECRET="simple-install-secret-2024-%RANDOM%">> .env.local
echo JWT_SECRET="simple-jwt-secret-2024-%RANDOM%">> .env.local
echo.>> .env.local
echo # Email>> .env.local
echo SMTP_HOST="smtp.gmail.com">> .env.local
echo SMTP_PORT=587>> .env.local
echo SMTP_USER="">> .env.local
echo SMTP_PASS="">> .env.local
echo.>> .env.local
echo # File Upload>> .env.local
echo UPLOAD_MAX_SIZE=26214400>> .env.local
echo ALLOWED_FILE_TYPES="pdf,jpg,jpeg,png,docx">> .env.local
echo.>> .env.local
echo # App Config>> .env.local
echo APP_NAME="Calendariko">> .env.local
echo DEFAULT_TIMEZONE="Europe/Rome">> .env.local

if exist ".env.local" (
    echo OK - File di configurazione creato
) else (
    echo ERRORE - Creazione configurazione fallita
)

echo.
echo ==========================================
echo       FASE 5: SCRIPT AVVIO
echo ==========================================

echo Creazione script di avvio...

echo @echo off> C:\Calendariko\Avvia-Calendariko.bat
echo title Calendariko - Sistema Calendario Band>> C:\Calendariko\Avvia-Calendariko.bat
echo.>> C:\Calendariko\Avvia-Calendariko.bat
echo echo ========================================>> C:\Calendariko\Avvia-Calendariko.bat
echo echo    CALENDARIKO - AVVIO APPLICAZIONE>> C:\Calendariko\Avvia-Calendariko.bat  
echo echo ========================================>> C:\Calendariko\Avvia-Calendariko.bat
echo echo.>> C:\Calendariko\Avvia-Calendariko.bat
echo echo Controllo prerequisiti...>> C:\Calendariko\Avvia-Calendariko.bat
echo.>> C:\Calendariko\Avvia-Calendariko.bat
echo node --version ^>nul 2^>^&1>> C:\Calendariko\Avvia-Calendariko.bat
echo if errorlevel 1 ^(>> C:\Calendariko\Avvia-Calendariko.bat
echo     echo ERRORE - Node.js non trovato>> C:\Calendariko\Avvia-Calendariko.bat
echo     echo Installare da https://nodejs.org>> C:\Calendariko\Avvia-Calendariko.bat
echo     pause>> C:\Calendariko\Avvia-Calendariko.bat
echo     exit>> C:\Calendariko\Avvia-Calendariko.bat
echo ^)>> C:\Calendariko\Avvia-Calendariko.bat
echo.>> C:\Calendariko\Avvia-Calendariko.bat
echo echo OK - Node.js disponibile>> C:\Calendariko\Avvia-Calendariko.bat
echo echo.>> C:\Calendariko\Avvia-Calendariko.bat
echo echo Controllo PostgreSQL...>> C:\Calendariko\Avvia-Calendariko.bat
echo netstat -an ^| findstr ":5432" ^>nul>> C:\Calendariko\Avvia-Calendariko.bat
echo if errorlevel 1 ^(>> C:\Calendariko\Avvia-Calendariko.bat
echo     echo.>> C:\Calendariko\Avvia-Calendariko.bat
echo     echo ERRORE - POSTGRESQL NON IN ESECUZIONE>> C:\Calendariko\Avvia-Calendariko.bat
echo     echo.>> C:\Calendariko\Avvia-Calendariko.bat
echo     echo DOCKER CONSIGLIATO:>> C:\Calendariko\Avvia-Calendariko.bat
echo     echo.>> C:\Calendariko\Avvia-Calendariko.bat
echo     echo docker run --name calendariko-postgres ^^>> C:\Calendariko\Avvia-Calendariko.bat
echo     echo   -e POSTGRES_PASSWORD=calendariko123 ^^>> C:\Calendariko\Avvia-Calendariko.bat
echo     echo   -e POSTGRES_DB=calendariko ^^>> C:\Calendariko\Avvia-Calendariko.bat
echo     echo   -p 5432:5432 -d postgres:15>> C:\Calendariko\Avvia-Calendariko.bat
echo     echo.>> C:\Calendariko\Avvia-Calendariko.bat
echo     echo INSTALLAZIONE MANUALE:>> C:\Calendariko\Avvia-Calendariko.bat
echo     echo 1. https://postgresql.org>> C:\Calendariko\Avvia-Calendariko.bat
echo     echo 2. Password: calendariko123>> C:\Calendariko\Avvia-Calendariko.bat
echo     echo 3. Creare database calendariko>> C:\Calendariko\Avvia-Calendariko.bat
echo     echo.>> C:\Calendariko\Avvia-Calendariko.bat
echo     set /p DB_CHOICE="Continuare dopo aver avviato PostgreSQL? (S/N): ">> C:\Calendariko\Avvia-Calendariko.bat
echo     if /i not "%%DB_CHOICE%%"=="S" exit>> C:\Calendariko\Avvia-Calendariko.bat
echo     echo.>> C:\Calendariko\Avvia-Calendariko.bat
echo     netstat -an ^| findstr ":5432" ^>nul>> C:\Calendariko\Avvia-Calendariko.bat
echo     if errorlevel 1 ^(>> C:\Calendariko\Avvia-Calendariko.bat
echo         echo ERRORE - PostgreSQL ancora non disponibile>> C:\Calendariko\Avvia-Calendariko.bat
echo         pause>> C:\Calendariko\Avvia-Calendariko.bat
echo         exit>> C:\Calendariko\Avvia-Calendariko.bat
echo     ^)>> C:\Calendariko\Avvia-Calendariko.bat
echo ^)>> C:\Calendariko\Avvia-Calendariko.bat
echo.>> C:\Calendariko\Avvia-Calendariko.bat
echo echo OK - PostgreSQL disponibile>> C:\Calendariko\Avvia-Calendariko.bat
echo echo.>> C:\Calendariko\Avvia-Calendariko.bat
echo cd /d "C:\Calendariko\app">> C:\Calendariko\Avvia-Calendariko.bat
echo.>> C:\Calendariko\Avvia-Calendariko.bat
echo echo Inizializzazione database...>> C:\Calendariko\Avvia-Calendariko.bat
echo npm run db:generate>> C:\Calendariko\Avvia-Calendariko.bat
echo npm run db:push>> C:\Calendariko\Avvia-Calendariko.bat  
echo npm run db:seed>> C:\Calendariko\Avvia-Calendariko.bat
echo.>> C:\Calendariko\Avvia-Calendariko.bat
echo echo OK - Database inizializzato>> C:\Calendariko\Avvia-Calendariko.bat
echo echo.>> C:\Calendariko\Avvia-Calendariko.bat
echo echo Avvio applicazione web...>> C:\Calendariko\Avvia-Calendariko.bat
echo echo.>> C:\Calendariko\Avvia-Calendariko.bat
echo echo URL: http://localhost:3000>> C:\Calendariko\Avvia-Calendariko.bat
echo echo Admin: admin@calendariko.com / admin123>> C:\Calendariko\Avvia-Calendariko.bat
echo echo Manager: manager1@example.com / manager123>> C:\Calendariko\Avvia-Calendariko.bat
echo echo Member: member1@example.com / member123>> C:\Calendariko\Avvia-Calendariko.bat
echo echo.>> C:\Calendariko\Avvia-Calendariko.bat
echo echo Apertura browser...>> C:\Calendariko\Avvia-Calendariko.bat
echo timeout /t 3 ^>nul>> C:\Calendariko\Avvia-Calendariko.bat
echo start "" "http://localhost:3000">> C:\Calendariko\Avvia-Calendariko.bat
echo.>> C:\Calendariko\Avvia-Calendariko.bat
echo echo Avvio server...>> C:\Calendariko\Avvia-Calendariko.bat
echo npm run dev>> C:\Calendariko\Avvia-Calendariko.bat

echo @echo off> C:\Calendariko\Stop-Calendariko.bat
echo title Calendariko - Stop>> C:\Calendariko\Stop-Calendariko.bat
echo echo Terminazione Calendariko...>> C:\Calendariko\Stop-Calendariko.bat
echo taskkill /f /im node.exe 2^>nul>> C:\Calendariko\Stop-Calendariko.bat
echo echo OK - Servizi arrestati>> C:\Calendariko\Stop-Calendariko.bat
echo timeout /t 2 ^>nul>> C:\Calendariko\Stop-Calendariko.bat

echo OK - Script di avvio creati

echo Creazione collegamento desktop...
powershell -ExecutionPolicy Bypass -Command "$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%USERPROFILE%\Desktop\Calendariko.lnk'); $Shortcut.TargetPath = 'C:\Calendariko\Avvia-Calendariko.bat'; $Shortcut.WorkingDirectory = 'C:\Calendariko\app'; $Shortcut.Description = 'Avvia Calendariko'; $Shortcut.Save()" 2>nul

echo OK - Setup completato

echo.
echo ==========================================
echo        INSTALLAZIONE COMPLETATA
echo ==========================================
echo.
echo Calendariko installato in: C:\Calendariko\
echo Collegamento desktop: Calendariko.lnk
echo Script configurati e pronti
echo.
echo PROSSIMI PASSI:
echo.
echo 1. AVVIARE POSTGRESQL:
echo    Docker: comando fornito nello script
echo    Manuale: https://postgresql.org
echo.
echo 2. AVVIARE CALENDARIKO:
echo    Doppio clic su Calendariko sul desktop
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
echo COMPLETATO - Installazione riuscita
echo Fare doppio clic su Calendariko sul desktop per iniziare
echo.
pause