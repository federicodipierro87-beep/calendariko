@echo off
title Calendariko - Installazione Semplificata
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
    echo.
) else (
    echo ❌ Node.js non trovato!
    echo.
    echo Installazione Node.js automatica in corso...
    echo (Questo potrebbe richiedere alcuni minuti)
    echo.
    
    :: Download Node.js
    echo Download Node.js LTS...
    powershell -command "& { Invoke-WebRequest -Uri 'https://nodejs.org/dist/v20.10.0/node-v20.10.0-x64.msi' -OutFile '%TEMP%\node-installer.msi' -UseBasicParsing }"
    
    if exist "%TEMP%\node-installer.msi" (
        echo ✓ Download completato
        echo.
        echo Installazione Node.js...
        msiexec /i "%TEMP%\node-installer.msi" /quiet /norestart ADDLOCAL=ALL
        
        echo ✓ Node.js installato
        
        :: Aggiorna PATH per la sessione corrente
        set "PATH=%PATH%;%ProgramFiles%\nodejs"
        
        :: Verifica installazione
        timeout /t 5 >nul
        node --version >nul 2>&1
        if %errorLevel% equ 0 (
            echo ✓ Verifica Node.js completata:
            node --version
        ) else (
            echo ❌ Verifica Node.js fallita
            echo Riavviare il prompt dei comandi e riprovare
            pause
            exit /b 1
        )
        
        :: Cleanup
        del "%TEMP%\node-installer.msi" 2>nul
    ) else (
        echo ❌ Download Node.js fallito
        echo.
        echo Installare manualmente da: https://nodejs.org
        echo Poi riavviare questo installer
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

:: Copia tutti i file eccetto alcune cartelle
xcopy /E /I /H /Y "..\*" "C:\Calendariko\app\" /EXCLUDE:exclude.txt

echo ✓ File applicazione copiati in C:\Calendariko\app\

echo.
echo ==========================================
echo      FASE 3: DIPENDENZE NPM
echo ==========================================

cd /d "C:\Calendariko\app"

echo Installazione dipendenze NPM...
echo (Questo può richiedere 2-5 minuti)
echo.

echo Esecuzione: npm install
echo Attendere...

npm install --no-optional --no-fund --loglevel=error

set NPM_EXIT_CODE=%errorLevel%

echo.
echo Exit code NPM: %NPM_EXIT_CODE%

if %NPM_EXIT_CODE% equ 0 (
    echo ✓ Dipendenze NPM installate correttamente
) else (
    echo ❌ Errore durante npm install (Exit Code: %NPM_EXIT_CODE%)
    echo.
    echo Informazioni di debug:
    echo - Directory corrente: %CD%
    echo - Node.js versione:
    node --version 2>nul || echo "Node.js non trovato"
    echo - NPM versione:
    npm --version 2>nul || echo "NPM non trovato"
    echo.
    echo Verificare:
    echo - Connessione internet attiva
    echo - Spazio disco sufficiente (almeno 500MB)
    echo - Permessi scrittura nella directory
    echo - Antivirus non blocca npm
    echo.
    echo Tentativo di diagnosi automatica...
    echo.
    if exist "package.json" (
        echo ✓ package.json trovato
    ) else (
        echo ❌ package.json mancante!
        echo File nella directory:
        dir /b
    )
    echo.
    set /p RETRY="Riprovare l'installazione NPM? (S/N): "
    if /i "%RETRY%"=="S" (
        echo.
        echo Nuovo tentativo con logging dettagliato...
        npm install --verbose
        set NPM_RETRY_CODE=!errorLevel!
        if !NPM_RETRY_CODE! equ 0 (
            echo ✓ Installazione riuscita al secondo tentativo
        ) else (
            echo ❌ Installazione fallita anche al secondo tentativo
            pause
            exit /b 1
        )
    ) else (
        echo Installazione annullata dall'utente
        pause
        exit /b 1
    )
)

echo.
echo ==========================================
echo     FASE 4: CONFIGURAZIONE
echo ==========================================

:: Crea file di configurazione
echo Creazione file .env.local...

echo # Database > "C:\Calendariko\app\.env.local"
echo DATABASE_URL="postgresql://postgres:calendariko123@localhost:5432/calendariko" >> "C:\Calendariko\app\.env.local"
echo. >> "C:\Calendariko\app\.env.local"
echo # Auth >> "C:\Calendariko\app\.env.local"
echo NEXTAUTH_URL="http://localhost:3000" >> "C:\Calendariko\app\.env.local"
echo NEXTAUTH_SECRET="simple-install-secret-2024" >> "C:\Calendariko\app\.env.local"
echo JWT_SECRET="simple-jwt-secret-2024" >> "C:\Calendariko\app\.env.local"
echo. >> "C:\Calendariko\app\.env.local"
echo # Email ^(configurare se necessario^) >> "C:\Calendariko\app\.env.local"
echo SMTP_HOST="smtp.gmail.com" >> "C:\Calendariko\app\.env.local"
echo SMTP_PORT=587 >> "C:\Calendariko\app\.env.local"
echo SMTP_USER="" >> "C:\Calendariko\app\.env.local"
echo SMTP_PASS="" >> "C:\Calendariko\app\.env.local"
echo. >> "C:\Calendariko\app\.env.local"
echo # App Config >> "C:\Calendariko\app\.env.local"
echo APP_NAME="Calendariko" >> "C:\Calendariko\app\.env.local"
echo DEFAULT_TIMEZONE="Europe/Rome" >> "C:\Calendariko\app\.env.local"

echo ✓ File di configurazione creato

echo.
echo ==========================================
echo       FASE 5: SCRIPT AVVIO
echo ==========================================

:: Script di avvio principale
echo @echo off > "C:\Calendariko\Avvia-Calendariko.bat"
echo title Calendariko - Sistema Calendario Band >> "C:\Calendariko\Avvia-Calendariko.bat"
echo. >> "C:\Calendariko\Avvia-Calendariko.bat"
echo echo ======================================== >> "C:\Calendariko\Avvia-Calendariko.bat"
echo echo    CALENDARIKO - AVVIO APPLICAZIONE >> "C:\Calendariko\Avvia-Calendariko.bat"
echo echo ======================================== >> "C:\Calendariko\Avvia-Calendariko.bat"
echo echo. >> "C:\Calendariko\Avvia-Calendariko.bat"
echo echo Controllo PostgreSQL... >> "C:\Calendariko\Avvia-Calendariko.bat"
echo netstat -an ^| findstr ":5432" ^>nul >> "C:\Calendariko\Avvia-Calendariko.bat"
echo if errorlevel 1 ^( >> "C:\Calendariko\Avvia-Calendariko.bat"
echo     echo. >> "C:\Calendariko\Avvia-Calendariko.bat"
echo     echo ❌ POSTGRESQL NON IN ESECUZIONE! >> "C:\Calendariko\Avvia-Calendariko.bat"
echo     echo. >> "C:\Calendariko\Avvia-Calendariko.bat"
echo     echo Per avviare PostgreSQL scegliere una opzione: >> "C:\Calendariko\Avvia-Calendariko.bat"
echo     echo. >> "C:\Calendariko\Avvia-Calendariko.bat"
echo     echo OPZIONE 1 - DOCKER ^(PIU' SEMPLICE^): >> "C:\Calendariko\Avvia-Calendariko.bat"
echo     echo   docker run --name calendariko-postgres ^^  >> "C:\Calendariko\Avvia-Calendariko.bat"
echo     echo     -e POSTGRES_PASSWORD=calendariko123 ^^  >> "C:\Calendariko\Avvia-Calendariko.bat"
echo     echo     -e POSTGRES_DB=calendariko ^^  >> "C:\Calendariko\Avvia-Calendariko.bat"
echo     echo     -p 5432:5432 -d postgres:15 >> "C:\Calendariko\Avvia-Calendariko.bat"
echo     echo. >> "C:\Calendariko\Avvia-Calendariko.bat"
echo     echo OPZIONE 2 - INSTALLAZIONE MANUALE: >> "C:\Calendariko\Avvia-Calendariko.bat"
echo     echo   1. Scaricare da: https://postgresql.org >> "C:\Calendariko\Avvia-Calendariko.bat"
echo     echo   2. Installare con password: calendariko123 >> "C:\Calendariko\Avvia-Calendariko.bat"
echo     echo   3. Creare database: calendariko >> "C:\Calendariko\Avvia-Calendariko.bat"
echo     echo. >> "C:\Calendariko\Avvia-Calendariko.bat"
echo     echo OPZIONE 3 - DATABASE ESISTENTE: >> "C:\Calendariko\Avvia-Calendariko.bat"
echo     echo   Modificare C:\Calendariko\app\.env.local >> "C:\Calendariko\Avvia-Calendariko.bat"
echo     echo   con i parametri del vostro database >> "C:\Calendariko\Avvia-Calendariko.bat"
echo     echo. >> "C:\Calendariko\Avvia-Calendariko.bat"
echo     pause >> "C:\Calendariko\Avvia-Calendariko.bat"
echo     exit >> "C:\Calendariko\Avvia-Calendariko.bat"
echo ^) >> "C:\Calendariko\Avvia-Calendariko.bat"
echo. >> "C:\Calendariko\Avvia-Calendariko.bat"
echo echo ✓ PostgreSQL in esecuzione >> "C:\Calendariko\Avvia-Calendariko.bat"
echo echo. >> "C:\Calendariko\Avvia-Calendariko.bat"
echo cd /d "C:\Calendariko\app" >> "C:\Calendariko\Avvia-Calendariko.bat"
echo. >> "C:\Calendariko\Avvia-Calendariko.bat"
echo echo Inizializzazione database... >> "C:\Calendariko\Avvia-Calendariko.bat"
echo npm run db:generate >> "C:\Calendariko\Avvia-Calendariko.bat"
echo npm run db:push >> "C:\Calendariko\Avvia-Calendariko.bat"
echo npm run db:seed >> "C:\Calendariko\Avvia-Calendariko.bat"
echo. >> "C:\Calendariko\Avvia-Calendariko.bat"
echo echo ✓ Database inizializzato >> "C:\Calendariko\Avvia-Calendariko.bat"
echo echo. >> "C:\Calendariko\Avvia-Calendariko.bat"
echo echo Avvio applicazione web... >> "C:\Calendariko\Avvia-Calendariko.bat"
echo echo. >> "C:\Calendariko\Avvia-Calendariko.bat"
echo echo ✓ URL: http://localhost:3000 >> "C:\Calendariko\Avvia-Calendariko.bat"
echo echo ✓ Admin: admin@calendariko.com / admin123 >> "C:\Calendariko\Avvia-Calendariko.bat"
echo echo ✓ Manager: manager1@example.com / manager123 >> "C:\Calendariko\Avvia-Calendariko.bat"
echo echo ✓ Member: member1@example.com / member123 >> "C:\Calendariko\Avvia-Calendariko.bat"
echo echo. >> "C:\Calendariko\Avvia-Calendariko.bat"
echo echo Apertura browser... >> "C:\Calendariko\Avvia-Calendariko.bat"
echo timeout /t 3 ^>nul >> "C:\Calendariko\Avvia-Calendariko.bat"
echo start "" "http://localhost:3000" >> "C:\Calendariko\Avvia-Calendariko.bat"
echo. >> "C:\Calendariko\Avvia-Calendariko.bat"
echo npm run dev >> "C:\Calendariko\Avvia-Calendariko.bat"

:: Script per terminare
echo @echo off > "C:\Calendariko\Stop-Calendariko.bat"
echo title Calendariko - Stop >> "C:\Calendariko\Stop-Calendariko.bat"
echo echo Terminazione Calendariko... >> "C:\Calendariko\Stop-Calendariko.bat"
echo taskkill /f /im node.exe 2^>nul >> "C:\Calendariko\Stop-Calendariko.bat"
echo echo ✓ Servizi arrestati >> "C:\Calendariko\Stop-Calendariko.bat"
echo timeout /t 3 ^>nul >> "C:\Calendariko\Stop-Calendariko.bat"

echo ✓ Script di avvio creati

:: Collegamento desktop
echo Creazione collegamento desktop...
powershell -command "& { $WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%USERPROFILE%\Desktop\Calendariko.lnk'); $Shortcut.TargetPath = 'C:\Calendariko\Avvia-Calendariko.bat'; $Shortcut.WorkingDirectory = 'C:\Calendariko'; $Shortcut.Description = 'Avvia Calendariko'; $Shortcut.Save() }"

echo ✓ Collegamento desktop creato

echo.
echo ==========================================
echo        INSTALLAZIONE COMPLETATA!
echo ==========================================
echo.
echo ✅ Calendariko installato in: C:\Calendariko\
echo ✅ Collegamento desktop creato
echo ✅ Script di avvio configurati
echo.
echo 📋 PROSSIMI PASSI:
echo.
echo 1️⃣ AVVIARE POSTGRESQL:
echo    Scegliere una delle opzioni quando si avvia Calendariko
echo.
echo 2️⃣ AVVIARE CALENDARIKO:
echo    Doppio clic su "Calendariko" sul desktop
echo.
echo 📊 ACCESSO:
echo    URL: http://localhost:3000
echo    Admin: admin@calendariko.com / admin123
echo.
echo 💡 SUGGERIMENTO:
echo    Docker è la soluzione più semplice per PostgreSQL!
echo    Installare Docker Desktop e usare il comando fornito.
echo.
echo ==========================================
echo.

set /p START_NOW="Aprire la cartella di installazione ora? (S/N): "
if /i "%START_NOW%"=="S" (
    explorer C:\Calendariko
)

echo.
echo Installazione completata! 
echo Fare doppio clic su "Calendariko" sul desktop per iniziare.
echo.
pause