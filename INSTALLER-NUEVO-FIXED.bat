@echo off

:: Forza la directory corretta
cd /d "%~dp0"

title Calendariko - Installer

cls
echo.
echo ==========================================
echo    CALENDARIKO - INSTALLER AUTOMATICO
echo ==========================================
echo.
echo Questo installer installera automaticamente:
echo 1. Node.js (se necessario)
echo 2. Copia file applicazione
echo 3. Dipendenze NPM
echo 4. Configurazione
echo 5. Script di avvio
echo.
echo Database PostgreSQL richiede installazione separata.
echo.
pause

echo.
echo FASE 1: Verifica Node.js
echo ==========================================
node --version >nul 2>&1
if %errorlevel% equ 0 (
    echo Node.js trovato:
    node --version
    npm --version
    goto copia_file
)

echo Node.js non trovato. Installazione in corso...
echo.
echo Download Node.js...

powershell -command "Invoke-WebRequest -Uri 'https://nodejs.org/dist/v20.10.0/node-v20.10.0-x64.msi' -OutFile '%TEMP%\node.msi'"

if not exist "%TEMP%\node.msi" (
    echo Errore download. Installare manualmente da nodejs.org
    pause
    exit
)

echo Installazione Node.js...
msiexec /i "%TEMP%\node.msi" /quiet /norestart

echo Attesa installazione...
timeout /t 20 >nul

del "%TEMP%\node.msi"

echo Verifica installazione...
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Errore installazione Node.js
    echo Riavviare il computer e riprovare
    pause
    exit
)

echo Node.js installato correttamente
node --version
npm --version

:copia_file
echo.
echo FASE 2: Copia file applicazione
echo ==========================================

if not exist "C:\Calendariko" mkdir "C:\Calendariko"
if not exist "C:\Calendariko\app" mkdir "C:\Calendariko\app"

echo Copia in corso...

if not exist "package.json" (
    echo Errore: package.json non trovato nella directory corrente
    echo Eseguire questo script dalla directory principale di Calendariko
    pause
    exit
)

xcopy /E /I /H /Y "." "C:\Calendariko\app\" >nul

echo Pulizia directory...
if exist "C:\Calendariko\app\node_modules" rmdir /s /q "C:\Calendariko\app\node_modules"
if exist "C:\Calendariko\app\.next" rmdir /s /q "C:\Calendariko\app\.next"

echo File copiati in C:\Calendariko\app

echo.
echo FASE 3: Installazione dipendenze NPM
echo ==========================================

cd /d "C:\Calendariko\app"

echo Installazione in corso...
echo (Attendere 3-5 minuti senza premere tasti)
echo.

npm install

if %errorlevel% neq 0 (
    echo.
    echo Errore durante npm install
    echo Riprovare manualmente con: cd C:\Calendariko\app && npm install
    pause
)

echo Dipendenze installate

echo.
echo FASE 4: Configurazione
echo ==========================================

echo Creazione file .env.local...

echo DATABASE_URL="postgresql://postgres:calendariko123@localhost:5432/calendariko" > .env.local
echo NEXTAUTH_URL="http://localhost:3000" >> .env.local
echo NEXTAUTH_SECRET="installer-secret-%RANDOM%" >> .env.local
echo JWT_SECRET="installer-jwt-%RANDOM%" >> .env.local
echo APP_NAME="Calendariko" >> .env.local
echo DEFAULT_TIMEZONE="Europe/Rome" >> .env.local

echo File configurazione creato

echo.
echo FASE 5: Script di avvio
echo ==========================================

echo Creazione script avvio...

echo @echo off > C:\Calendariko\Avvia-Calendariko.bat
echo title Calendariko >> C:\Calendariko\Avvia-Calendariko.bat
echo. >> C:\Calendariko\Avvia-Calendariko.bat
echo echo Controllo PostgreSQL... >> C:\Calendariko\Avvia-Calendariko.bat
echo netstat -an ^| findstr ":5432" ^>nul >> C:\Calendariko\Avvia-Calendariko.bat
echo if errorlevel 1 ^( >> C:\Calendariko\Avvia-Calendariko.bat
echo     echo. >> C:\Calendariko\Avvia-Calendariko.bat
echo     echo PostgreSQL non in esecuzione! >> C:\Calendariko\Avvia-Calendariko.bat
echo     echo. >> C:\Calendariko\Avvia-Calendariko.bat
echo     echo DOCKER: >> C:\Calendariko\Avvia-Calendariko.bat
echo     echo docker run --name postgres-cal ^^ >> C:\Calendariko\Avvia-Calendariko.bat
echo     echo   -e POSTGRES_PASSWORD=calendariko123 ^^ >> C:\Calendariko\Avvia-Calendariko.bat
echo     echo   -e POSTGRES_DB=calendariko ^^ >> C:\Calendariko\Avvia-Calendariko.bat
echo     echo   -p 5432:5432 -d postgres:15 >> C:\Calendariko\Avvia-Calendariko.bat
echo     echo. >> C:\Calendariko\Avvia-Calendariko.bat
echo     echo MANUALE: https://postgresql.org >> C:\Calendariko\Avvia-Calendariko.bat
echo     echo Password: calendariko123 >> C:\Calendariko\Avvia-Calendariko.bat
echo     echo Database: calendariko >> C:\Calendariko\Avvia-Calendariko.bat
echo     echo. >> C:\Calendariko\Avvia-Calendariko.bat
echo     pause >> C:\Calendariko\Avvia-Calendariko.bat
echo     exit >> C:\Calendariko\Avvia-Calendariko.bat
echo ^) >> C:\Calendariko\Avvia-Calendariko.bat
echo. >> C:\Calendariko\Avvia-Calendariko.bat
echo cd /d "C:\Calendariko\app" >> C:\Calendariko\Avvia-Calendariko.bat
echo. >> C:\Calendariko\Avvia-Calendariko.bat
echo echo Inizializzazione database... >> C:\Calendariko\Avvia-Calendariko.bat
echo npm run db:generate >> C:\Calendariko\Avvia-Calendariko.bat
echo npm run db:push >> C:\Calendariko\Avvia-Calendariko.bat
echo npm run db:seed >> C:\Calendariko\Avvia-Calendariko.bat
echo. >> C:\Calendariko\Avvia-Calendariko.bat
echo echo Database pronto >> C:\Calendariko\Avvia-Calendariko.bat
echo echo. >> C:\Calendariko\Avvia-Calendariko.bat
echo echo Avvio applicazione... >> C:\Calendariko\Avvia-Calendariko.bat
echo echo URL: http://localhost:3000 >> C:\Calendariko\Avvia-Calendariko.bat
echo echo Admin: admin@calendariko.com / admin123 >> C:\Calendariko\Avvia-Calendariko.bat
echo echo. >> C:\Calendariko\Avvia-Calendariko.bat
echo start "" "http://localhost:3000" >> C:\Calendariko\Avvia-Calendariko.bat
echo timeout /t 3 ^>nul >> C:\Calendariko\Avvia-Calendariko.bat
echo npm run dev >> C:\Calendariko\Avvia-Calendariko.bat

echo @echo off > C:\Calendariko\Stop-Calendariko.bat
echo echo Arresto Calendariko... >> C:\Calendariko\Stop-Calendariko.bat
echo taskkill /f /im node.exe 2^>nul >> C:\Calendariko\Stop-Calendariko.bat
echo echo Arrestato >> C:\Calendariko\Stop-Calendariko.bat
echo timeout /t 2 ^>nul >> C:\Calendariko\Stop-Calendariko.bat

echo Script creati

echo Creazione collegamento desktop...
powershell -command "$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%USERPROFILE%\Desktop\Calendariko.lnk'); $Shortcut.TargetPath = 'C:\Calendariko\Avvia-Calendariko.bat'; $Shortcut.Save()"

echo.
echo ==========================================
echo         INSTALLAZIONE COMPLETATA
echo ==========================================
echo.
echo Calendariko installato in: C:\Calendariko\
echo.
echo PROSSIMI PASSI:
echo.
echo 1. Installare PostgreSQL:
echo    - Docker: usare comando nello script
echo    - Manuale: https://postgresql.org
echo    - Password: calendariko123
echo    - Database: calendariko
echo.
echo 2. Avviare Calendariko:
echo    Doppio clic su "Calendariko" sul desktop
echo.
echo 3. Aprire browser:
echo    http://localhost:3000
echo    Login: admin@calendariko.com / admin123
echo.
echo ==========================================

pause