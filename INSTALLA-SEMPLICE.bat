@echo off
title Calendariko - Installazione Diretta

cls
echo.
echo =========================================
echo   CALENDARIKO - INSTALLAZIONE DIRETTA
echo =========================================
echo.
echo Questo installer installera automaticamente:
echo 1. Node.js (se necessario)
echo 2. File applicazione
echo 3. Dipendenze NPM
echo 4. Configurazione
echo 5. Script di avvio
echo.
echo Database PostgreSQL richiede setup separato.
echo.

pause

:: Vai alla directory installer
cd /d "%~dp0\installer"

:: Controlla quale versione eseguire
if exist "Simple-Install-ASCII.bat" (
    echo Esecuzione versione ASCII...
    call Simple-Install-ASCII.bat
) else if exist "Simple-Install-Clean.bat" (
    echo Esecuzione versione pulita...
    call Simple-Install-Clean.bat
) else if exist "Simple-Install-Fixed.bat" (
    echo Esecuzione versione fixed...  
    call Simple-Install-Fixed.bat
) else if exist "Simple-Install.bat" (
    echo Esecuzione versione base...
    call Simple-Install.bat
) else (
    echo ERRORE: Nessun installer trovato nella cartella installer/
    echo.
    echo Verificare che esistano i file nella cartella installer/
    echo.
    pause
    exit /b 1
)

echo.
echo ==========================================
echo Installazione completata!
echo ==========================================
pause