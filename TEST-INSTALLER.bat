@echo off
cls
echo TEST INSTALLER CALENDARIKO
echo ==========================
echo.

echo Test 1: Verifica directory
echo Directory corrente: %CD%
echo.
if exist "package.json" (
    echo OK - package.json trovato
) else (
    echo ERRORE - package.json non trovato
    echo Eseguire dalla directory principale di Calendariko
    pause
    exit
)
echo.

echo Test 2: Verifica Node.js
node --version >nul 2>&1
if %errorlevel% equ 0 (
    echo OK - Node.js trovato
    node --version
    npm --version
) else (
    echo ERRORE - Node.js non trovato
    echo Scaricare da: https://nodejs.org
    pause
    exit
)
echo.

echo Test 3: Creazione directory
if not exist "C:\Calendariko-Test" mkdir "C:\Calendariko-Test"
if exist "C:\Calendariko-Test" (
    echo OK - Directory di test creata
) else (
    echo ERRORE - Impossibile creare directory
    pause
    exit
)
echo.

echo Test 4: Copia file di test
echo Copia package.json...
copy "package.json" "C:\Calendariko-Test\" >nul
if exist "C:\Calendariko-Test\package.json" (
    echo OK - Copia file funziona
) else (
    echo ERRORE - Copia file fallita
    pause
    exit
)
echo.

echo Test 5: Test NPM
cd "C:\Calendariko-Test"
echo Installazione dipendenza di test...
echo {"name":"test","dependencies":{"lodash":"^4.17.21"}} > package.json
npm install lodash --silent >nul 2>&1
if exist "node_modules" (
    echo OK - NPM funziona
) else (
    echo ERRORE - NPM non funziona
    echo Verificare connessione internet
)
echo.

cd /d "%~dp0"
echo Pulizia test...
rmdir /s /q "C:\Calendariko-Test" 2>nul

echo.
echo ==========================
echo TUTTI I TEST COMPLETATI
echo ==========================
echo.
echo Se tutti i test sono OK, procedere con:
echo INSTALLER-NUOVO.bat
echo.
pause