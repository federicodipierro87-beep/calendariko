Write-Host "TEST INSTALLER CALENDARIKO" -ForegroundColor Green
Write-Host "=========================="
Write-Host ""

Write-Host "Test 1: Verifica directory" -ForegroundColor Yellow
Write-Host "Directory corrente: $PWD"
Write-Host ""

if (Test-Path "package.json") {
    Write-Host "OK - package.json trovato" -ForegroundColor Green
} else {
    Write-Host "ERRORE - package.json non trovato" -ForegroundColor Red
    Write-Host "Eseguire dalla directory principale di Calendariko"
    Read-Host "Premere Enter per uscire"
    exit
}
Write-Host ""

Write-Host "Test 2: Verifica Node.js" -ForegroundColor Yellow
try {
    $nodeVersion = node --version 2>$null
    if ($nodeVersion) {
        Write-Host "OK - Node.js trovato" -ForegroundColor Green
        Write-Host "Versione Node.js: $nodeVersion"
        $npmVersion = npm --version 2>$null
        Write-Host "Versione NPM: $npmVersion"
    } else {
        throw "Node.js not found"
    }
} catch {
    Write-Host "ERRORE - Node.js non trovato" -ForegroundColor Red
    Write-Host "Scaricare da: https://nodejs.org"
    Read-Host "Premere Enter per uscire"
    exit
}
Write-Host ""

Write-Host "Test 3: Verifica connessione internet" -ForegroundColor Yellow
try {
    $ping = Test-NetConnection -ComputerName "registry.npmjs.org" -Port 80 -InformationLevel Quiet
    if ($ping) {
        Write-Host "OK - Connessione internet disponibile" -ForegroundColor Green
    } else {
        Write-Host "AVVISO - Connessione internet non disponibile" -ForegroundColor Yellow
    }
} catch {
    Write-Host "AVVISO - Impossibile verificare connessione" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "=========================="
Write-Host "RIEPILOGO TEST" -ForegroundColor Green
Write-Host "=========================="
Write-Host ""
Write-Host "TUTTI I TEST PRINCIPALI SUPERATI" -ForegroundColor Green
Write-Host ""
Write-Host "Pronto per l'installazione!"
Write-Host ""
Write-Host "PROSSIMO PASSO:"
Write-Host "1. Eseguire: ./INSTALLER-CALENDARIKO.ps1"
Write-Host ""

Read-Host "Premere Enter per continuare"