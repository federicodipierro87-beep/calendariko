@echo off
title Calendariko - Installer Automatico

:: Verifica privilegi amministratore
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERRORE: Questo installer richiede privilegi di amministratore.
    echo.
    echo Fare clic destro su questo file e selezionare "Esegui come amministratore"
    echo.
    pause
    exit /b 1
)

cls
echo =========================================
echo       CALENDARIKO INSTALLER v1.0
echo =========================================
echo Sistema di gestione calendario per band
echo.
echo Questo installer automatizzerà:
echo 1. Installazione Node.js (se necessario)
echo 2. Download PostgreSQL portatile  
echo 3. Installazione dipendenze NPM
echo 4. Configurazione database
echo 5. Inizializzazione applicazione
echo 6. Creazione collegamenti desktop
echo.
echo Requisiti: Windows 10/11, 2GB spazio, Internet
echo Tempo stimato: 5-10 minuti
echo =========================================
echo.

set /p CONTINUE="Continuare con l'installazione? (S/N): "
if /i not "%CONTINUE%"=="S" (
    echo Installazione annullata.
    pause
    exit /b 0
)

echo.
echo Avvio script PowerShell di installazione...
echo.

:: Cambia alla directory dell'installer
cd /d "%~dp0"

:: Esegui lo script PowerShell con ExecutionPolicy Bypass
powershell.exe -ExecutionPolicy Bypass -WindowStyle Normal -File "scripts\install.ps1" -Unattended

if %errorLevel% equ 0 (
    echo.
    echo =========================================
    echo   INSTALLAZIONE COMPLETATA CON SUCCESSO!
    echo =========================================
    echo.
    echo Calendariko è ora installato e pronto all'uso.
    echo Fare doppio clic sull'icona "Calendariko" sul desktop per avviare.
    echo.
    echo URL: http://localhost:3000
    echo.
    echo Account demo:
    echo - Admin: admin@calendariko.com / admin123
    echo - Manager: manager1@example.com / manager123
    echo - Member: member1@example.com / member123
    echo.
) else (
    echo.
    echo =========================================
    echo      ERRORE DURANTE L'INSTALLAZIONE
    echo =========================================
    echo.
    echo L'installazione non è stata completata correttamente.
    echo Controllare i messaggi di errore sopra.
    echo.
    echo Per supporto: https://github.com/calendariko
    echo.
)

pause