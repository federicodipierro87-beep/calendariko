Write-Host ""
Write-Host "     ██████╗ █████╗ ██╗     ███████╗███╗   ██╗██████╗  █████╗ ██████╗ ██╗██╗  ██╗ ██████╗ " -ForegroundColor Cyan
Write-Host "    ██╔════╝██╔══██╗██║     ██╔════╝████╗  ██║██╔══██╗██╔══██╗██╔══██╗██║██║ ██╔╝██╔═══██╗" -ForegroundColor Cyan
Write-Host "    ██║     ███████║██║     █████╗  ██╔██╗ ██║██║  ██║███████║██████╔╝██║█████╔╝ ██║   ██║" -ForegroundColor Cyan
Write-Host "    ██║     ██╔══██║██║     ██╔══╝  ██║╚██╗██║██║  ██║██╔══██║██╔══██╗██║██╔═██╗ ██║   ██║" -ForegroundColor Cyan
Write-Host "    ╚██████╗██║  ██║███████╗███████╗██║ ╚████║██████╔╝██║  ██║██║  ██║██║██║  ██╗╚██████╔╝" -ForegroundColor Cyan
Write-Host "     ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═══╝╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝ ╚═════╝ " -ForegroundColor Cyan
Write-Host ""
Write-Host "                        Sistema di Gestione Calendario per Band v1.0" -ForegroundColor White
Write-Host ""
Write-Host "    ══════════════════════════════════════════════════════════════════════════════════════" -ForegroundColor Gray
Write-Host "                                   SCEGLI INSTALLAZIONE" -ForegroundColor Yellow
Write-Host "    ══════════════════════════════════════════════════════════════════════════════════════" -ForegroundColor Gray
Write-Host ""
Write-Host "    [1] 🧪 TEST SISTEMA (CONSIGLIATO PRIMA)" -ForegroundColor Green
Write-Host "        ✓ Verifica requisiti (Node.js, connessione, directory)" -ForegroundColor Gray
Write-Host "        ✓ Controlla se tutto è pronto per l'installazione" -ForegroundColor Gray
Write-Host "        ✓ Non installa nulla, solo verifica" -ForegroundColor Gray
Write-Host ""
Write-Host "    [2] 🚀 INSTALLAZIONE AUTOMATICA COMPLETA" -ForegroundColor Cyan
Write-Host "        ✓ Installa Node.js automaticamente se necessario" -ForegroundColor Gray
Write-Host "        ✓ Configura applicazione completa con npm install" -ForegroundColor Gray
Write-Host "        ✓ Crea script di avvio e collegamento desktop" -ForegroundColor Gray
Write-Host "        ✓ Pronta all'uso in 5-10 minuti" -ForegroundColor Gray
Write-Host ""
Write-Host "    [3] 📖 INFORMAZIONI E REQUISITI" -ForegroundColor Yellow
Write-Host ""
Write-Host "    [4] 🚪 ESCI" -ForegroundColor Red
Write-Host ""
Write-Host "    ══════════════════════════════════════════════════════════════════════════════════════" -ForegroundColor Gray

do {
    $choice = Read-Host "    Seleziona un'opzione [1-4]"
    
    switch ($choice) {
        "1" {
            Write-Host ""
            Write-Host "🧪 Avvio test sistema..." -ForegroundColor Green
            Write-Host ""
            & "$PSScriptRoot\TEST-INSTALLER.ps1"
            break
        }
        "2" {
            Write-Host ""
            Write-Host "🚀 Avvio installazione automatica..." -ForegroundColor Cyan
            Write-Host ""
            & "$PSScriptRoot\INSTALLER-CALENDARIKO.ps1"
            break
        }
        "3" {
            Write-Host ""
            Write-Host "    ══════════════════════════════════════════════════════════════════════════════════════" -ForegroundColor Gray
            Write-Host "                                  INFORMAZIONI CALENDARIKO" -ForegroundColor Yellow
            Write-Host "    ══════════════════════════════════════════════════════════════════════════════════════" -ForegroundColor Gray
            Write-Host ""
            Write-Host "    📋 DESCRIZIONE:" -ForegroundColor White
            Write-Host "    Calendariko è un sistema di gestione calendario professionale progettato" -ForegroundColor Gray
            Write-Host "    specificatamente per band musicali e agenzie di spettacolo. Permette la" -ForegroundColor Gray
            Write-Host "    gestione centralizzata di eventi, concerti e indisponibilità con controllo" -ForegroundColor Gray
            Write-Host "    accessi basato sui ruoli." -ForegroundColor Gray
            Write-Host ""
            Write-Host "    🎯 CARATTERISTICHE PRINCIPALI:" -ForegroundColor White
            Write-Host "    • Gestione multi-band con ruoli (Admin, Manager, Member)" -ForegroundColor Gray
            Write-Host "    • Calendar interattivo con vista mese/settimana/giorno" -ForegroundColor Gray
            Write-Host "    • Gestione eventi: Concerti, Indisponibilità, Blocchi Agenzia" -ForegroundColor Gray
            Write-Host "    • Sistema di permessi granulare e sicurezza avanzata" -ForegroundColor Gray
            Write-Host "    • Interface mobile-responsive e PWA" -ForegroundColor Gray
            Write-Host "    • Gestione venue, cachet e dettagli finanziari" -ForegroundColor Gray
            Write-Host ""
            Write-Host "    💻 REQUISITI SISTEMA:" -ForegroundColor White
            Write-Host "    • Windows 10/11 (64-bit)" -ForegroundColor Gray
            Write-Host "    • 4GB RAM (consigliati 8GB)" -ForegroundColor Gray
            Write-Host "    • 2GB spazio disco libero" -ForegroundColor Gray
            Write-Host "    • Connessione internet (per installazione)" -ForegroundColor Gray
            Write-Host "    • PostgreSQL 13+ o Docker per il database" -ForegroundColor Gray
            Write-Host ""
            Write-Host "    🔧 DOPO L'INSTALLAZIONE:" -ForegroundColor White
            Write-Host "    • URL Applicazione: http://localhost:3000" -ForegroundColor Gray
            Write-Host "    • Admin: admin@calendariko.com / admin123" -ForegroundColor Gray
            Write-Host "    • Manager: manager1@example.com / manager123" -ForegroundColor Gray
            Write-Host "    • Member: member1@example.com / member123" -ForegroundColor Gray
            Write-Host ""
            Write-Host "    💡 CONSIGLIO: Eseguire prima il Test Sistema per verificare i requisiti!" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "    ══════════════════════════════════════════════════════════════════════════════════════" -ForegroundColor Gray
            Write-Host ""
            Read-Host "    Premere Enter per tornare al menu"
            
            # Recursive call to show menu again
            & $MyInvocation.MyCommand.Path
            return
        }
        "4" {
            Write-Host ""
            Write-Host "    Grazie per aver scelto Calendariko!" -ForegroundColor Green
            Write-Host ""
            Write-Host "    Per informazioni e supporto:" -ForegroundColor Gray
            Write-Host "    🌐 https://github.com/calendariko" -ForegroundColor Gray
            Write-Host "    📧 support@calendariko.com" -ForegroundColor Gray
            Write-Host ""
            Write-Host "    🎵 Buona gestione dei tuoi eventi musicali! 🎼" -ForegroundColor Cyan
            Write-Host ""
            Start-Sleep -Seconds 2
            exit
        }
        default {
            Write-Host ""
            Write-Host "    ❌ Opzione non valida. Riprovare." -ForegroundColor Red
            Write-Host ""
        }
    }
} while ($choice -notin @("1","2","3","4"))