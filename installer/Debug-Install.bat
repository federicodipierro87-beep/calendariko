@echo off
title Calendariko - Debug Install
color 0E

echo =========================================
echo   CALENDARIKO - INSTALLAZIONE DEBUG
echo =========================================
echo.
echo Questa versione fornisce output dettagliato
echo per identificare eventuali problemi.
echo.
pause

echo.
echo === FASE 1: INFORMAZIONI SISTEMA ===
echo.
echo Sistema operativo:
ver
echo.
echo Directory corrente:
echo %CD%
echo.
echo Variabili PATH:
echo %PATH%
echo.

echo === FASE 2: VERIFICA NODE.JS ===
echo.
echo Controllo Node.js...
node --version
if %errorLevel% equ 0 (
    echo ✓ Node.js trovato
    echo Versione NPM:
    npm --version
) else (
    echo ❌ Node.js NON trovato
    echo.
    echo Installazione Node.js...
    echo Download in corso...
    
    powershell -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri 'https://nodejs.org/dist/v20.10.0/node-v20.10.0-x64.msi' -OutFile '%TEMP%\node-installer.msi'"
    
    if exist "%TEMP%\node-installer.msi" (
        echo Download completato
        echo Installazione...
        msiexec /i "%TEMP%\node-installer.msi" /quiet /norestart
        echo Attesa installazione...
        timeout /t 30
        
        :: Ricarica PATH
        call refreshenv 2>nul
        
        echo Verifica post-installazione:
        node --version
    ) else (
        echo ❌ Download fallito
    )
)

echo.
echo === FASE 3: VERIFICA FILE SORGENTI ===
echo.
echo Directory installer: %CD%
echo.
echo File nella directory corrente:
dir /b
echo.
echo Controllo directory parent:
cd ..
echo Directory parent: %CD%
echo.
echo File nella directory parent:
dir /b
echo.

if exist "package.json" (
    echo ✓ package.json trovato
    echo Contenuto package.json:
    type package.json | findstr "name\|version"
) else (
    echo ❌ package.json NON trovato
    echo.
    echo Ricerca package.json in sottocartelle:
    for /d %%i in (*) do (
        if exist "%%i\package.json" (
            echo Trovato in: %%i\
        )
    )
)

echo.
echo === FASE 4: CREAZIONE DIRECTORY TARGET ===
echo.
if not exist "C:\Calendariko" (
    mkdir "C:\Calendariko"
    echo ✓ Directory C:\Calendariko creata
) else (
    echo ✓ Directory C:\Calendariko già esistente
)

if not exist "C:\Calendariko\app" (
    mkdir "C:\Calendariko\app"
    echo ✓ Directory C:\Calendariko\app creata
) else (
    echo ✓ Directory C:\Calendariko\app già esistente
)

echo.
echo === FASE 5: COPIA FILE ===
echo.
echo Copia da: %CD%
echo Copia a: C:\Calendariko\app
echo.

robocopy "." "C:\Calendariko\app" /E /XD node_modules .next .git installer dist /XF *.log *.pid .env.local /V

set ROBOCOPY_EXIT=%errorLevel%
echo.
echo Exit code robocopy: %ROBOCOPY_EXIT%

if %ROBOCOPY_EXIT% leq 7 (
    echo ✓ Copia completata
    echo.
    echo File copiati in C:\Calendariko\app:
    dir "C:\Calendariko\app" /b
) else (
    echo ❌ Errore copia con robocopy
    echo.
    echo Tentativo con xcopy:
    xcopy /E /I /Y "*" "C:\Calendariko\app\"
    
    if !errorLevel! equ 0 (
        echo ✓ Copia con xcopy riuscita
    ) else (
        echo ❌ Errore anche con xcopy
    )
)

echo.
echo === FASE 6: VERIFICA FILE COPIATI ===
echo.
cd "C:\Calendariko\app"
echo Directory corrente: %CD%
echo.

if exist "package.json" (
    echo ✓ package.json presente
    echo Contenuto:
    type package.json | findstr "name\|version"
) else (
    echo ❌ package.json mancante dopo copia
    echo File presenti:
    dir /b
)

echo.
echo === FASE 7: TEST NPM INSTALL ===
echo.
echo Esecuzione npm install con output completo:
echo.

npm install --verbose --no-optional

set NPM_EXIT=%errorLevel%
echo.
echo Exit code npm install: %NPM_EXIT%

if %NPM_EXIT% equ 0 (
    echo ✓ NPM install completato con successo
    echo.
    echo Verifica node_modules:
    if exist "node_modules" (
        echo ✓ Directory node_modules creata
        dir node_modules | find "Directory"
    ) else (
        echo ❌ Directory node_modules non creata
    )
) else (
    echo ❌ NPM install fallito
    echo.
    echo Informazioni aggiuntive:
    echo - Node.js path: %PROGRAMFILES%\nodejs
    echo - NPM config:
    npm config list
    echo.
    echo Cache NPM:
    npm cache verify
    echo.
    echo Registry NPM:
    npm config get registry
)

echo.
echo === FASE 8: CONFIGURAZIONE ===
echo.
echo Creazione .env.local:

(
echo DATABASE_URL="postgresql://postgres:calendariko123@localhost:5432/calendariko"
echo NEXTAUTH_URL="http://localhost:3000"
echo NEXTAUTH_SECRET="debug-install-secret"
echo JWT_SECRET="debug-jwt-secret"
echo APP_NAME="Calendariko"
echo DEFAULT_TIMEZONE="Europe/Rome"
) > ".env.local"

if exist ".env.local" (
    echo ✓ File .env.local creato
    echo Contenuto:
    type ".env.local"
) else (
    echo ❌ Errore creazione .env.local
)

echo.
echo ==========================================
echo           DEBUG COMPLETATO
echo ==========================================
echo.
echo Se tutto è andato bene, ora dovresti poter:
echo 1. Avviare PostgreSQL (Docker o manuale)
echo 2. Eseguire: npm run db:generate
echo 3. Eseguire: npm run db:push  
echo 4. Eseguire: npm run db:seed
echo 5. Eseguire: npm run dev
echo 6. Aprire: http://localhost:3000
echo.
echo File di log salvato in: debug-install.log
echo.
pause

:: Salva log
echo === DEBUG INSTALL LOG === > debug-install.log
echo Data: %date% %time% >> debug-install.log
echo Directory: %CD% >> debug-install.log
echo Node.js: >> debug-install.log
node --version >> debug-install.log 2>&1
echo NPM: >> debug-install.log
npm --version >> debug-install.log 2>&1
echo File presenti: >> debug-install.log
dir /b >> debug-install.log