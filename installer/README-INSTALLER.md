# 📦 Calendariko - Installer Automatico

Questo pacchetto di installazione automatizza completamente l'installazione di Calendariko su sistemi Windows.

## 🚀 Installazione Rapida

### Metodo 1: Installer Batch (Consigliato)
1. **Fare clic destro** su `Install-Calendariko.bat`
2. Selezionare **"Esegui come amministratore"**
3. Seguire le istruzioni a schermo
4. ✅ Installazione completata!

### Metodo 2: PowerShell Diretto
```powershell
# Aprire PowerShell come amministratore
Set-ExecutionPolicy Bypass -Scope Process
.\scripts\install.ps1
```

## 📋 Cosa Viene Installato

### Software Automatico
- ✅ **Node.js LTS** (v20.10.0) - Se non già presente
- ✅ **PostgreSQL Portatile** (v15.5) - In `C:\Calendariko\postgresql`
- ✅ **Calendariko App** - In `C:\Calendariko\app`

### Configurazione Automatica
- ✅ Database PostgreSQL locale sulla porta 5432
- ✅ Database "calendariko" con dati demo
- ✅ File `.env.local` con configurazione completa
- ✅ Dipendenze NPM installate
- ✅ Schema database applicato
- ✅ Dati di esempio popolati

### Script e Collegamenti
- ✅ **Desktop**: Collegamento "Calendariko"
- ✅ **Avvio Completo**: `Avvia-Calendariko.bat`
- ✅ **Solo PostgreSQL**: `Start-PostgreSQL.bat`
- ✅ **Solo App**: `Start-Calendariko.bat`
- ✅ **Stop Servizi**: `Stop-Calendariko.bat`
- ✅ **Disinstallazione**: `Uninstall-Calendariko.bat`

## 🖥️ Requisiti Sistema

| Componente | Requisito Minimo |
|------------|------------------|
| **OS** | Windows 10/11 (64-bit) |
| **RAM** | 4GB (consigliati 8GB) |
| **Spazio Disco** | 2GB liberi |
| **Rete** | Connessione internet per download |
| **Privilegi** | Amministratore (per installazione) |

## ⚙️ Parametri Personalizzazione

Lo script PowerShell accetta parametri personalizzati:

```powershell
# Installazione personalizzata
.\scripts\install.ps1 -InstallPath "D:\MiaCartella\Calendariko" -DatabasePort 5433 -AppPort 8080

# Salta installazione Node.js se già presente
.\scripts\install.ps1 -SkipNodeInstall

# Installazione silenziosa
.\scripts\install.ps1 -Unattended
```

### Parametri Disponibili
- `-InstallPath` - Percorso installazione (default: `C:\Calendariko`)
- `-DatabasePort` - Porta PostgreSQL (default: `5432`)
- `-AppPort` - Porta applicazione web (default: `3000`)
- `-DatabasePassword` - Password database (default: `calendariko123`)
- `-SkipNodeInstall` - Salta installazione Node.js
- `-SkipPostgreSQLInstall` - Salta installazione PostgreSQL
- `-Unattended` - Installazione senza interazione utente

## 🎯 Dopo l'Installazione

### Avvio Rapido
1. **Doppio clic** su **"Calendariko"** sul desktop
2. Attendere avvio servizi (15-30 secondi)
3. Il browser si aprirà automaticamente su `http://localhost:3000`

### Account Demo Preconfigurati

| Tipo | Email | Password | Accesso |
|------|-------|----------|---------|
| **Admin** | admin@calendariko.com | admin123 | Tutte le band, gestione utenti |
| **Manager** | manager1@example.com | manager123 | Gestione The Rockers |
| **Manager** | manager2@example.com | manager123 | Gestione Jazz Collective |
| **Member** | member1@example.com | member123 | Solo visualizzazione The Rockers |
| **Member** | member2@example.com | member123 | Solo visualizzazione Jazz Collective |

### Avvio Manuale Servizi

Se necessario, è possibile avviare i servizi manualmente:

```batch
# 1. Avvia PostgreSQL
C:\Calendariko\Start-PostgreSQL.bat

# 2. Avvia applicazione (in altra finestra)
C:\Calendariko\Start-Calendariko.bat
```

## 🔧 Risoluzione Problemi

### Errore: "Node.js non trovato"
- Riavviare il terminale/computer dopo installazione Node.js
- Verificare PATH: `node --version`

### Errore: "Porta già in uso"
```batch
# Controllare processi in uso
netstat -ano | findstr :3000
netstat -ano | findstr :5432

# Terminare processi se necessario
taskkill /f /pid XXXX
```

### Errore: "Database non raggiungibile"
```batch
# Riavviare PostgreSQL
C:\Calendariko\Stop-Calendariko.bat
C:\Calendariko\Start-PostgreSQL.bat
```

### Reset Completo Database
```batch
cd C:\Calendariko\app
npm run db:push --force-reset
npm run db:seed
```

## 📁 Struttura File Installazione

```
C:\Calendariko\
├── 📂 postgresql\          # Server PostgreSQL portatile
│   ├── bin\               # Eseguibili PostgreSQL
│   └── lib\               # Librerie
├── 📂 data\               # Dati database PostgreSQL
├── 📂 app\                # Applicazione Calendariko
│   ├── src\              # Codice sorgente
│   ├── node_modules\     # Dipendenze NPM
│   └── .env.local        # Configurazione
├── 📄 Avvia-Calendariko.bat      # Script avvio completo
├── 📄 Start-PostgreSQL.bat       # Avvio solo database
├── 📄 Start-Calendariko.bat      # Avvio solo app
├── 📄 Stop-Calendariko.bat       # Stop tutti i servizi
└── 📄 Uninstall-Calendariko.bat  # Disinstallazione
```

## 🗑️ Disinstallazione

Per rimuovere completamente Calendariko:

1. **Eseguire**: `C:\Calendariko\Uninstall-Calendariko.bat`
2. Confermare la rimozione
3. ✅ Tutti i file e servizi verranno rimossi

> ⚠️ **Nota**: Node.js non viene rimosso automaticamente in quanto potrebbe essere utilizzato da altre applicazioni.

## 🛡️ Sicurezza

### Configurazione Default
- Database PostgreSQL accessibile solo localmente
- Password database generata casualmente
- JWT secrets generati automaticamente
- Nessun servizio esposto pubblicamente

### Configurazione Produzione
Per uso in produzione, modificare:
- Password database in `.env.local`
- JWT_SECRET e NEXTAUTH_SECRET
- Configurazione SMTP per email
- Backup automatici database

## 📞 Supporto

### Log di Installazione
I log sono salvati in:
- `%TEMP%\calendariko-install.log`
- `C:\Calendariko\app\.next\trace` (runtime)

### Assistenza
- **GitHub Issues**: https://github.com/calendariko/issues
- **Email**: support@calendariko.com
- **Documentazione**: https://docs.calendariko.com

---

## 🎵 Buon Lavoro con Calendariko!

Il tuo sistema di gestione calendario per band è ora pronto all'uso. Buona gestione eventi! 🎼