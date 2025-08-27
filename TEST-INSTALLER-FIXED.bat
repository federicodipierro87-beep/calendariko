@echo off

:: Forza la directory corretta
cd /d "%~dp0"

cls
echo TEST INSTALLER CALENDARIKO
echo ==========================
echo.

echo Test 1: Verifica directory
echo Directory corrente: %CD%
echo File script: %~dp0
echo.
if exist "package.json" (
    echo OK - package.json trovato
) else (
    echo ERRORE - package.json non trovato
    echo.
    echo La directory dovrebbe contenere:
    echo - package.json
    echo - src/
    echo - prisma/
    echo - next.config.mjs
    echo.
    echo Verificare di aver estratto correttamente Calendariko
    pause
    exit
)

if exist "src" (
    echo OK - directory src trovata
) else (
    echo ERRORE - directory src non trovata
)

if exist "prisma" (
    echo OK - directory prisma trovata
) else (
    echo ERRORE - directory prisma non trovata
)
echo.

echo Test 2: Verifica Node.js
node --version >nul 2>&1
if %errorlevel% equ 0 (
    echo OK - Node.js trovato
    echo Versione Node.js:
    node --version
    echo Versione NPM:
    npm --version
) else (
    echo ERRORE - Node.js non trovato
    echo.
    echo Scaricare e installare Node.js LTS da:
    echo https://nodejs.org
    echo.
    echo Dopo l'installazione riavviare questo test
    pause
    exit
)
echo.

echo Test 3: Verifica permessi scrittura
echo Test scrittura in C:\
echo test > "C:\test-calendariko.tmp" 2>nul
if exist "C:\test-calendariko.tmp" (
    echo OK - Permessi scrittura OK
    del "C:\test-calendariko.tmp"
) else (
    echo AVVISO - Potrebbero servire privilegi amministratore
    echo Fare clic destro sul file .bat e "Esegui come amministratore"
)
echo.

echo Test 4: Verifica connessione internet
ping -n 1 registry.npmjs.org >nul 2>&1
if %errorlevel% equ 0 (
    echo OK - Connessione internet disponibile
) else (
    echo AVVISO - Connessione internet non disponibile
    echo NPM install potrebbe fallire
)
echo.

echo Test 5: Verifica spazio disco
for /f "tokens=3" %%i in ('dir /-c  ^| find "byte"') do set bytes=%%i
if defined bytes (
    echo OK - Spazio disco disponibile
) else (
    echo AVVISO - Impossibile verificare spazio disco
)
echo.

echo ==========================
echo RIEPILOGO TEST
echo ==========================
echo.
if exist "package.json" (
    if defined NODE_VERSION (
        echo TUTTI I TEST PRINCIPALI SUPERATI
        echo.
        echo Pronto per l'installazione!
        echo.
        echo PROSSIMO PASSO:
        echo 1. Eseguire: INSTALLER-NUOVO-FIXED.bat
        echo    oppure
        echo 2. Eseguire: INSTALLA-STEP-BY-STEP-FIXED.bat
    ) else (
        echo INSTALLARE NODE.JS PRIMA DI CONTINUARE
    )
) else (
    echo VERIFICARE LA DIRECTORY DI CALENDARIKO
)
echo.
pause