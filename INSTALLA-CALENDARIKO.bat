@echo off
title Calendariko - Installer Principale
color 0B

cls
echo.
echo     ██████╗ █████╗ ██╗     ███████╗███╗   ██╗██████╗  █████╗ ██████╗ ██╗██╗  ██╗ ██████╗ 
echo    ██╔════╝██╔══██╗██║     ██╔════╝████╗  ██║██╔══██╗██╔══██╗██╔══██╗██║██║ ██╔╝██╔═══██╗
echo    ██║     ███████║██║     █████╗  ██╔██╗ ██║██║  ██║███████║██████╔╝██║█████╔╝ ██║   ██║
echo    ██║     ██╔══██║██║     ██╔══╝  ██║╚██╗██║██║  ██║██╔══██║██╔══██╗██║██╔═██╗ ██║   ██║
echo    ╚██████╗██║  ██║███████╗███████╗██║ ╚████║██████╔╝██║  ██║██║  ██║██║██║  ██╗╚██████╔╝
echo     ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═══╝╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝ ╚═════╝ 
echo.
echo                         Sistema di Gestione Calendario per Band v1.0
echo.
echo    ═══════════════════════════════════════════════════════════════════════════════════════
echo                                    SCEGLI TIPO DI INSTALLAZIONE
echo    ═══════════════════════════════════════════════════════════════════════════════════════
echo.
echo    [1] 🚀 INSTALLAZIONE SEMPLICE (CONSIGLIATA)
echo        ✓ Installa Node.js automaticamente se necessario
echo        ✓ Configura applicazione completa con npm install
echo        ✓ Guida setup PostgreSQL (Docker o manuale)
echo        ✓ Pronta all'uso in 3-5 minuti - PIU' STABILE
echo        ✓ Testata e affidabile
echo.
echo    [2] 🔧 INSTALLAZIONE AVANZATA (PowerShell)
echo        ✓ Script PowerShell automatico completo
echo        ✓ Tenta configurazione PostgreSQL automatica
echo        ✓ Per utenti esperti e sperimentatori
echo        ✓ Richiede privilegi amministratore
echo.
echo    [3] ⚡ INSTALLAZIONE RAPIDA (SOLO FILE)
echo        ✓ Copia solo i file dell'applicazione
echo        ✓ Richiede installazione manuale Node.js + PostgreSQL
echo        ✓ Per sviluppatori o chi ha già i requisiti
echo.
echo    [4] 📖 MOSTRA INFORMAZIONI E REQUISITI
echo.
echo    [5] 🚪 ESCI
echo.
echo    ═══════════════════════════════════════════════════════════════════════════════════════

:choice
set /p choice="    Seleziona un'opzione [1-5]: "

if "%choice%"=="1" goto simple_install
if "%choice%"=="2" goto advanced_install
if "%choice%"=="3" goto quick_install  
if "%choice%"=="4" goto show_info
if "%choice%"=="5" goto exit
echo.
echo    ❌ Opzione non valida. Riprovare.
echo.
goto choice

:show_info
cls
echo.
echo    ═══════════════════════════════════════════════════════════════════════════════════════
echo                                   INFORMAZIONI CALENDARIKO
echo    ═══════════════════════════════════════════════════════════════════════════════════════
echo.
echo    📋 DESCRIZIONE:
echo    Calendariko è un sistema di gestione calendario professionale progettato
echo    specificatamente per band musicali e agenzie di spettacolo. Permette la
echo    gestione centralizzata di eventi, concerti e indisponibilità con controllo
echo    accessi basato sui ruoli.
echo.
echo    🎯 CARATTERISTICHE PRINCIPALI:
echo    • Gestione multi-band con ruoli (Admin, Manager, Member)
echo    • Calendar interattivo con vista mese/settimana/giorno
echo    • Gestione eventi: Concerti, Indisponibilità, Blocchi Agenzia
echo    • Sistema di permessi granulare e sicurezza avanzata
echo    • Interface mobile-responsive e PWA
echo    • Gestione venue, cachet e dettagli finanziari
echo.
echo    💻 REQUISITI SISTEMA:
echo    • Windows 10/11 (64-bit)
echo    • 4GB RAM (consigliati 8GB)  
echo    • 2GB spazio disco libero
echo    • Connessione internet (per installazione)
echo    • Privilegi amministratore (per installazione automatica Node.js)
echo.
echo    🔧 DOPO L'INSTALLAZIONE:
echo    • URL Applicazione: http://localhost:3000
echo    • Admin: admin@calendariko.com / admin123
echo    • Manager: manager1@example.com / manager123
echo    • Member: member1@example.com / member123
echo.
echo    📞 SUPPORTO:
echo    • GitHub: https://github.com/calendariko
echo    • Email: support@calendariko.com
echo    • Docs: https://docs.calendariko.com
echo.
echo    💡 CONSIGLIO: Usare l'Installazione Semplice per la migliore esperienza!
echo.
echo    ═══════════════════════════════════════════════════════════════════════════════════════
echo.
pause
cls
goto choice

:simple_install
cls
echo.
echo    ═══════════════════════════════════════════════════════════════════════════════════════
echo                               INSTALLAZIONE SEMPLICE (CONSIGLIATA)
echo    ═══════════════════════════════════════════════════════════════════════════════════════
echo.
echo    Questa installazione automatizzerà:
echo    ✓ Controllo e installazione Node.js LTS (se necessario)
echo    ✓ Copia completa file applicazione
echo    ✓ Installazione dipendenze (npm install)
echo    ✓ Configurazione ambiente di produzione
echo    ✓ Creazione script di avvio intelligente
echo    ✓ Collegamenti desktop
echo.
echo    🎯 VANTAGGI:
echo    • Processo testato e stabile
echo    • Guida chiara per setup PostgreSQL
echo    • Supporto Docker e installazione manuale
echo    • Meno problemi di compatibilità
echo.
echo    📁 Percorso installazione: C:\Calendariko\
echo    🕒 Tempo stimato: 3-5 minuti
echo.
set /p confirm="    Continuare con l'installazione semplice? (S/N): "
if /i not "%confirm%"=="S" goto choice

echo.
echo    🚀 Avvio installazione semplice...
echo.

cd /d "%~dp0\installer"
if exist "Simple-Install-ASCII.bat" (
    call Simple-Install-ASCII.bat
) else if exist "Simple-Install-Clean.bat" (
    call Simple-Install-Clean.bat
) else if exist "Simple-Install-Fixed.bat" (
    call Simple-Install-Fixed.bat
) else (
    call Simple-Install.bat
)

echo.
pause
goto choice

:advanced_install
cls
echo.
echo    ═══════════════════════════════════════════════════════════════════════════════════════
echo                               INSTALLAZIONE AVANZATA (PowerShell)
echo    ═══════════════════════════════════════════════════════════════════════════════════════
echo.
echo    Questa installazione userà PowerShell per:
echo    ✓ Download e installazione Node.js LTS automatica
echo    ✓ Tentativo configurazione PostgreSQL automatica
echo    ✓ Setup completo database e applicazione
echo    ✓ Installazione dipendenze e inizializzazione
echo    ✓ Script di avvio completi
echo    ✓ Collegamenti desktop e menu Start
echo.
echo    ⚠️  IMPORTANTE: 
echo    • Richiede privilegi di amministratore
echo    • Connessione internet attiva per i download
echo    • Processo sperimentale - può richiedere configurazione aggiuntiva
echo.
echo    📁 Percorso installazione: C:\Calendariko\
echo    🕒 Tempo stimato: 8-15 minuti
echo.
set /p confirm="    Continuare con l'installazione avanzata? (S/N): "
if /i not "%confirm%"=="S" goto choice

echo.
echo    🔧 Avvio installazione avanzata...
echo.

:: Verifica privilegi amministratore
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo    ❌ ERRORE: Privilegi amministratore richiesti!
    echo.
    echo    Fare clic destro su questo file e selezionare 
    echo    "Esegui come amministratore" per continuare.
    echo.
    pause
    goto choice
)

:: Cambia alla directory installer e avvia
cd /d "%~dp0\installer"
call Install-Calendariko.bat

echo.
pause
goto choice

:quick_install
cls
echo.
echo    ═══════════════════════════════════════════════════════════════════════════════════════
echo                                   INSTALLAZIONE RAPIDA
echo    ═══════════════════════════════════════════════════════════════════════════════════════
echo.
echo    Questa installazione copierà solo i file dell'applicazione senza
echo    installare automaticamente i software richiesti.
echo.
echo    ✅ COSA INCLUDE:
echo    ✓ Copia file applicazione in C:\Calendariko\app\
echo    ✓ Creazione file di configurazione base
echo    ✓ Script di avvio semplificato
echo    ✓ Collegamento desktop
echo.
echo    ⚠️  COSA DEVI FARE MANUALMENTE DOPO:
echo    ❌ Installare Node.js LTS da: https://nodejs.org
echo    ❌ Installare PostgreSQL da: https://postgresql.org  
echo    ❌ Configurare database 'calendariko'
echo    ❌ Eseguire npm install nella cartella app
echo    ❌ Configurare file .env.local per produzione
echo.
echo    👨‍💻 ADATTA PER:
echo    • Sviluppatori che hanno già Node.js e PostgreSQL
echo    • Chi vuole controllare manualmente l'installazione
echo    • Installazioni su server o ambienti personalizzati
echo.
set /p confirm="    Continuare con installazione rapida? (S/N): "
if /i not "%confirm%"=="S" goto choice

echo.
echo    ⚡ Avvio installazione rapida...
echo.

cd /d "%~dp0\installer"
call Quick-Install.bat

echo.
pause
goto choice

:exit
cls
echo.
echo    Grazie per aver scelto Calendariko!
echo.
echo    Per informazioni e supporto:
echo    🌐 https://github.com/calendariko
echo    📧 support@calendariko.com
echo.
echo    🎵 Buona gestione dei tuoi eventi musicali! 🎼
echo.
timeout /t 3 >nul
exit /b 0