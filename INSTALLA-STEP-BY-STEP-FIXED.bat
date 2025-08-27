@echo off

:: Forza la directory corretta
cd /d "%~dp0"

title Calendariko - Installazione Step by Step

:menu
cls
echo.
echo ==========================================
echo    CALENDARIKO - INSTALLAZIONE GUIDATA
echo ==========================================
echo.
echo Scegliere cosa fare:
echo.
echo 1. Test prerequisiti
echo 2. Installa Node.js (se necessario)
echo 3. Copia file applicazione
echo 4. Installa dipendenze NPM
echo 5. Configura applicazione
echo 6. Crea script di avvio
echo 7. INSTALLAZIONE COMPLETA AUTOMATICA
echo.
echo 8. Esci
echo.

set /p scelta="Inserire numero (1-8): "

if "%scelta%"=="1" goto test
if "%scelta%"=="2" goto nodejs
if "%scelta%"=="3" goto copia
if "%scelta%"=="4" goto npm
if "%scelta%"=="5" goto config
if "%scelta%"=="6" goto script
if "%scelta%"=="7" goto completa
if "%scelta%"=="8" exit
goto menu

:test
cls
echo TEST PREREQUISITI
echo =================
echo.
echo Directory: %CD%
if exist "package.json" (
    echo [OK] package.json trovato
) else (
    echo [ERRORE] package.json non trovato
    echo Eseguire dalla directory di Calendariko
)
echo.
node --version >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Node.js disponibile
    node --version
    npm --version
) else (
    echo [ERRORE] Node.js non trovato
)
echo.
if exist "C:\Calendariko\app" (
    echo [OK] Directory installazione esiste
) else (
    echo [INFO] Directory installazione non esiste (normale)
)
echo.
pause
goto menu

:nodejs
cls
echo INSTALLAZIONE NODE.JS
echo ====================
echo.
node --version >nul 2>&1
if %errorlevel% equ 0 (
    echo Node.js gia installato:
    node --version
    npm --version
    pause
    goto menu
)

echo Node.js non trovato. Installazione...
echo.
echo Download in corso...
powershell -command "Invoke-WebRequest -Uri 'https://nodejs.org/dist/v20.10.0/node-v20.10.0-x64.msi' -OutFile '%TEMP%\nodejs.msi'"

if exist "%TEMP%\nodejs.msi" (
    echo Download completato
    echo.
    echo Installazione in corso...
    echo (Attendere qualche minuto)
    msiexec /i "%TEMP%\nodejs.msi" /quiet /norestart
    
    echo Attesa completamento...
    timeout /t 30
    
    del "%TEMP%\nodejs.msi"
    
    echo Verifica...
    node --version >nul 2>&1
    if %errorlevel% equ 0 (
        echo [OK] Node.js installato
        node --version
        npm --version
    ) else (
        echo [ERRORE] Installazione fallita
        echo Riavviare il computer e riprovare
    )
) else (
    echo [ERRORE] Download fallito
    echo Installare manualmente da: https://nodejs.org
)
echo.
pause
goto menu

:copia
cls
echo COPIA FILE APPLICAZIONE
echo ======================
echo.
if not exist "package.json" (
    echo [ERRORE] package.json non trovato
    echo Eseguire dalla directory di Calendariko
    pause
    goto menu
)

echo Creazione directory...
if not exist "C:\Calendariko" mkdir "C:\Calendariko"
if not exist "C:\Calendariko\app" mkdir "C:\Calendariko\app"

echo Copia file in corso...
xcopy /E /I /H /Y "." "C:\Calendariko\app\" >nul

echo Pulizia...
if exist "C:\Calendariko\app\node_modules" rmdir /s /q "C:\Calendariko\app\node_modules"
if exist "C:\Calendariko\app\.next" rmdir /s /q "C:\Calendariko\app\.next"

if exist "C:\Calendariko\app\package.json" (
    echo [OK] File copiati in C:\Calendariko\app
) else (
    echo [ERRORE] Copia fallita
)
echo.
pause
goto menu

:npm
cls
echo INSTALLAZIONE DIPENDENZE NPM
echo ============================
echo.
if not exist "C:\Calendariko\app\package.json" (
    echo [ERRORE] Applicazione non copiata
    echo Eseguire prima: 3. Copia file applicazione
    pause
    goto menu
)

cd /d "C:\Calendariko\app"

echo Directory: %CD%
echo.
echo Installazione dipendenze...
echo (Questo puo richiedere 5-10 minuti)
echo.

npm install

if %errorlevel% equ 0 (
    echo [OK] Dipendenze installate
) else (
    echo [ERRORE] Installazione dipendenze fallita
    echo Verificare connessione internet
)
echo.
cd /d "%~dp0"
pause
goto menu

:config
cls
echo CONFIGURAZIONE APPLICAZIONE
echo ===========================
echo.
if not exist "C:\Calendariko\app" (
    echo [ERRORE] Applicazione non installata
    pause
    goto menu
)

cd /d "C:\Calendariko\app"

echo Creazione file .env.local...
echo DATABASE_URL="postgresql://postgres:calendariko123@localhost:5432/calendariko" > .env.local
echo NEXTAUTH_URL="http://localhost:3000" >> .env.local
echo NEXTAUTH_SECRET="calendariko-secret-%RANDOM%" >> .env.local
echo JWT_SECRET="calendariko-jwt-%RANDOM%" >> .env.local
echo APP_NAME="Calendariko" >> .env.local
echo DEFAULT_TIMEZONE="Europe/Rome" >> .env.local

if exist ".env.local" (
    echo [OK] Configurazione creata
) else (
    echo [ERRORE] Creazione configurazione fallita
)

cd /d "%~dp0"
echo.
pause
goto menu

:script
cls
echo CREAZIONE SCRIPT DI AVVIO
echo =========================
echo.

echo Creazione Avvia-Calendariko.bat...
echo @echo off > C:\Calendariko\Avvia-Calendariko.bat
echo title Calendariko >> C:\Calendariko\Avvia-Calendariko.bat
echo echo Controllo PostgreSQL... >> C:\Calendariko\Avvia-Calendariko.bat
echo netstat -an ^| findstr ":5432" ^>nul >> C:\Calendariko\Avvia-Calendariko.bat
echo if errorlevel 1 ^( >> C:\Calendariko\Avvia-Calendariko.bat
echo     echo PostgreSQL non attivo >> C:\Calendariko\Avvia-Calendariko.bat
echo     echo DOCKER: docker run --name postgres -e POSTGRES_PASSWORD=calendariko123 -e POSTGRES_DB=calendariko -p 5432:5432 -d postgres:15 >> C:\Calendariko\Avvia-Calendariko.bat
echo     echo MANUALE: https://postgresql.org >> C:\Calendariko\Avvia-Calendariko.bat
echo     pause >> C:\Calendariko\Avvia-Calendariko.bat
echo     exit >> C:\Calendariko\Avvia-Calendariko.bat
echo ^) >> C:\Calendariko\Avvia-Calendariko.bat
echo cd /d "C:\Calendariko\app" >> C:\Calendariko\Avvia-Calendariko.bat
echo npm run db:generate >> C:\Calendariko\Avvia-Calendariko.bat
echo npm run db:push >> C:\Calendariko\Avvia-Calendariko.bat
echo npm run db:seed >> C:\Calendariko\Avvia-Calendariko.bat
echo echo Avvio su http://localhost:3000 >> C:\Calendariko\Avvia-Calendariko.bat
echo start "" "http://localhost:3000" >> C:\Calendariko\Avvia-Calendariko.bat
echo npm run dev >> C:\Calendariko\Avvia-Calendariko.bat

echo Collegamento desktop...
powershell -command "$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%USERPROFILE%\Desktop\Calendariko.lnk'); $Shortcut.TargetPath = 'C:\Calendariko\Avvia-Calendariko.bat'; $Shortcut.Save()"

echo [OK] Script di avvio creati
echo [OK] Collegamento desktop creato
echo.
pause
goto menu

:completa
cls
echo INSTALLAZIONE COMPLETA AUTOMATICA
echo =================================
echo.
echo Questo eseguira tutti i passi automaticamente:
echo 1. Installa Node.js (se necessario)
echo 2. Copia file
echo 3. Installa dipendenze
echo 4. Configura applicazione
echo 5. Crea script di avvio
echo.
set /p conferma="Continuare? (S/N): "
if /i not "%conferma%"=="S" goto menu

echo.
echo AVVIO INSTALLAZIONE COMPLETA...
echo.

:: Step 1: Node.js
echo [1/5] Controllo Node.js...
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Installazione Node.js...
    powershell -command "Invoke-WebRequest -Uri 'https://nodejs.org/dist/v20.10.0/node-v20.10.0-x64.msi' -OutFile '%TEMP%\nodejs.msi'"
    if exist "%TEMP%\nodejs.msi" (
        msiexec /i "%TEMP%\nodejs.msi" /quiet /norestart
        timeout /t 30
        del "%TEMP%\nodejs.msi"
    )
) else (
    echo Node.js gia presente
)

:: Step 2: Copia
echo [2/5] Copia file...
if not exist "C:\Calendariko" mkdir "C:\Calendariko"
if not exist "C:\Calendariko\app" mkdir "C:\Calendariko\app"
xcopy /E /I /H /Y "." "C:\Calendariko\app\" >nul
if exist "C:\Calendariko\app\node_modules" rmdir /s /q "C:\Calendariko\app\node_modules"
if exist "C:\Calendariko\app\.next" rmdir /s /q "C:\Calendariko\app\.next"

:: Step 3: NPM
echo [3/5] Installazione dipendenze...
cd /d "C:\Calendariko\app"
npm install

:: Step 4: Config
echo [4/5] Configurazione...
echo DATABASE_URL="postgresql://postgres:calendariko123@localhost:5432/calendariko" > .env.local
echo NEXTAUTH_URL="http://localhost:3000" >> .env.local
echo NEXTAUTH_SECRET="auto-install-%RANDOM%" >> .env.local
echo JWT_SECRET="auto-jwt-%RANDOM%" >> .env.local
echo APP_NAME="Calendariko" >> .env.local
echo DEFAULT_TIMEZONE="Europe/Rome" >> .env.local

:: Step 5: Script
echo [5/5] Script di avvio...
echo @echo off > C:\Calendariko\Avvia-Calendariko.bat
echo title Calendariko >> C:\Calendariko\Avvia-Calendariko.bat
echo cd /d "C:\Calendariko\app" >> C:\Calendariko\Avvia-Calendariko.bat
echo echo Avvio Calendariko... >> C:\Calendariko\Avvia-Calendariko.bat
echo echo URL: http://localhost:3000 >> C:\Calendariko\Avvia-Calendariko.bat
echo echo Admin: admin@calendariko.com / admin123 >> C:\Calendariko\Avvia-Calendariko.bat
echo start "" "http://localhost:3000" >> C:\Calendariko\Avvia-Calendariko.bat
echo npm run dev >> C:\Calendariko\Avvia-Calendariko.bat

powershell -command "$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%USERPROFILE%\Desktop\Calendariko.lnk'); $Shortcut.TargetPath = 'C:\Calendariko\Avvia-Calendariko.bat'; $Shortcut.Save()"

cd /d "%~dp0"

echo.
echo ==========================================
echo    INSTALLAZIONE COMPLETATA CON SUCCESSO
echo ==========================================
echo.
echo Calendariko installato in: C:\Calendariko\
echo Collegamento desktop creato: Calendariko.lnk
echo.
echo IMPORTANTE: Prima di avviare installare PostgreSQL
echo.
echo DOCKER (consigliato):
echo docker run --name postgres ^^
echo   -e POSTGRES_PASSWORD=calendariko123 ^^
echo   -e POSTGRES_DB=calendariko ^^
echo   -p 5432:5432 -d postgres:15
echo.
echo MANUALE:
echo https://postgresql.org
echo Password: calendariko123
echo Database: calendariko
echo.
echo Poi fare doppio clic su "Calendariko" sul desktop
echo.
pause
goto menu