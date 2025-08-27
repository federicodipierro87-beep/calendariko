@echo off
title Calendariko - Installazione Rapida

echo =========================================
echo    CALENDARIKO - INSTALLAZIONE RAPIDA
echo =========================================
echo.

:: Controllo amministratore
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ATTENZIONE: Privilegi amministratore necessari!
    echo.
    echo Fare clic destro su questo file e selezionare
    echo "Esegui come amministratore" per continuare.
    echo.
    pause
    exit /b 1
)

echo Creazione directory di installazione...
if not exist "C:\Calendariko" mkdir "C:\Calendariko"
if not exist "C:\Calendariko\app" mkdir "C:\Calendariko\app"

echo.
echo Copia file applicazione in corso...
xcopy /E /I /H /Y "..\*" "C:\Calendariko\app\" /EXCLUDE:installer\exclude.txt

echo.
echo Creazione file di configurazione...

echo # Database > "C:\Calendariko\app\.env.local"
echo DATABASE_URL="postgresql://postgres:calendariko123@localhost:5432/calendariko" >> "C:\Calendariko\app\.env.local"
echo. >> "C:\Calendariko\app\.env.local"
echo # Auth >> "C:\Calendariko\app\.env.local"
echo NEXTAUTH_URL="http://localhost:3000" >> "C:\Calendariko\app\.env.local"
echo NEXTAUTH_SECRET="quick-install-secret-change-in-production" >> "C:\Calendariko\app\.env.local"
echo JWT_SECRET="quick-jwt-secret-change-in-production" >> "C:\Calendariko\app\.env.local"
echo. >> "C:\Calendariko\app\.env.local"
echo # App Config >> "C:\Calendariko\app\.env.local"
echo APP_NAME="Calendariko" >> "C:\Calendariko\app\.env.local"
echo DEFAULT_TIMEZONE="Europe/Rome" >> "C:\Calendariko\app\.env.local"

echo.
echo Creazione script di avvio semplificato...

echo @echo off > "C:\Calendariko\Avvia-Solo-App.bat"
echo title Calendariko - Modalità Sviluppo >> "C:\Calendariko\Avvia-Solo-App.bat"
echo. >> "C:\Calendariko\Avvia-Solo-App.bat"
echo echo ======================================== >> "C:\Calendariko\Avvia-Solo-App.bat"
echo echo    CALENDARIKO - MODALITA' SVILUPPO >> "C:\Calendariko\Avvia-Solo-App.bat"
echo echo ======================================== >> "C:\Calendariko\Avvia-Solo-App.bat"
echo echo. >> "C:\Calendariko\Avvia-Solo-App.bat"
echo echo ATTENZIONE: Questa modalità richiede: >> "C:\Calendariko\Avvia-Solo-App.bat"
echo echo - Node.js installato manualmente >> "C:\Calendariko\Avvia-Solo-App.bat"
echo echo - PostgreSQL configurato manualmente >> "C:\Calendariko\Avvia-Solo-App.bat"
echo echo. >> "C:\Calendariko\Avvia-Solo-App.bat"
echo echo Per installazione completa automatica: >> "C:\Calendariko\Avvia-Solo-App.bat"
echo echo Usare Install-Calendariko.bat invece >> "C:\Calendariko\Avvia-Solo-App.bat"
echo echo. >> "C:\Calendariko\Avvia-Solo-App.bat"
echo pause >> "C:\Calendariko\Avvia-Solo-App.bat"
echo. >> "C:\Calendariko\Avvia-Solo-App.bat"
echo cd /d "C:\Calendariko\app" >> "C:\Calendariko\Avvia-Solo-App.bat"
echo. >> "C:\Calendariko\Avvia-Solo-App.bat"
echo echo Verifica Node.js... >> "C:\Calendariko\Avvia-Solo-App.bat"
echo node --version >> "C:\Calendariko\Avvia-Solo-App.bat"
echo if errorlevel 1 ( >> "C:\Calendariko\Avvia-Solo-App.bat"
echo     echo ERRORE: Node.js non trovato! >> "C:\Calendariko\Avvia-Solo-App.bat"
echo     echo Installare Node.js da: https://nodejs.org >> "C:\Calendariko\Avvia-Solo-App.bat"
echo     pause >> "C:\Calendariko\Avvia-Solo-App.bat"
echo     exit >> "C:\Calendariko\Avvia-Solo-App.bat"
echo ^) >> "C:\Calendariko\Avvia-Solo-App.bat"
echo. >> "C:\Calendariko\Avvia-Solo-App.bat"
echo echo Installazione dipendenze... >> "C:\Calendariko\Avvia-Solo-App.bat"
echo npm install >> "C:\Calendariko\Avvia-Solo-App.bat"
echo. >> "C:\Calendariko\Avvia-Solo-App.bat"
echo echo Avvio applicazione... >> "C:\Calendariko\Avvia-Solo-App.bat"
echo echo URL: http://localhost:3000 >> "C:\Calendariko\Avvia-Solo-App.bat"
echo echo. >> "C:\Calendariko\Avvia-Solo-App.bat"
echo npm run dev >> "C:\Calendariko\Avvia-Solo-App.bat"

echo.
echo Creazione collegamento desktop...
echo Set oWS = WScript.CreateObject("WScript.Shell") > "%TEMP%\CreateShortcut.vbs"
echo sLinkFile = "%USERPROFILE%\Desktop\Calendariko (Installazione Completa).lnk" >> "%TEMP%\CreateShortcut.vbs"
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> "%TEMP%\CreateShortcut.vbs"
echo oLink.TargetPath = "C:\Calendariko\Install-Calendariko.bat" >> "%TEMP%\CreateShortcut.vbs"
echo oLink.WorkingDirectory = "C:\Calendariko" >> "%TEMP%\CreateShortcut.vbs"
echo oLink.Description = "Installazione completa automatica di Calendariko" >> "%TEMP%\CreateShortcut.vbs"
echo oLink.Save >> "%TEMP%\CreateShortcut.vbs"

cscript //nologo "%TEMP%\CreateShortcut.vbs"
del "%TEMP%\CreateShortcut.vbs"

echo.
echo =========================================
echo     INSTALLAZIONE RAPIDA COMPLETATA
echo =========================================
echo.
echo File copiati in: C:\Calendariko\app
echo.
echo PROSSIMI PASSI:
echo.
echo OPZIONE 1 - INSTALLAZIONE AUTOMATICA COMPLETA:
echo   Fare doppio clic su "Calendariko (Installazione Completa)"
echo   sul desktop per installazione automatica completa.
echo.
echo OPZIONE 2 - CONFIGURAZIONE MANUALE:
echo   1. Installare Node.js da: https://nodejs.org
echo   2. Installare PostgreSQL da: https://postgresql.org
echo   3. Configurare database "calendariko" 
echo   4. Eseguire: C:\Calendariko\Avvia-Solo-App.bat
echo.
echo RACCOMANDAZIONE: Usare l'Opzione 1 per installazione
echo completamente automatica senza configurazione manuale.
echo.
pause