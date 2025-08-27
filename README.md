# Calendariko

Sistema di gestione calendario per band e agenzie di spettacolo. Permette a più band di condividere un calendario centralizzato con controllo degli accessi basato sui ruoli.

## Caratteristiche Principali

### 🎵 Gestione Multi-Band
- **Admin**: Visione completa di tutte le band e gli eventi
- **Manager**: Gestione completa della propria band
- **Member**: Visualizzazione e gestione eventi della propria band

### 📅 Calendar Management
- Vista calendario mensile, settimanale e giornaliera
- Creazione eventi drag & drop
- Tre tipi di eventi:
  - **Concerti**: Eventi pubblici con venue e dettagli finanziari
  - **Indisponibilità**: Blocchi privati per la band
  - **Blocco Agenzia**: Riservato agli amministratori

### 🔐 Sicurezza e Permessi
- Autenticazione JWT con refresh token
- Sistema ACL (Access Control List) per permessi granulari
- Privacy configurabile per eventi (Band/Agenzia)
- Audit log per tracciare tutte le modifiche

### 📱 Mobile-First Design
- Design responsive ottimizzato per mobile
- PWA (Progressive Web App) installabile
- Layout adattivo per tutti i dispositivi

## Tecnologie Utilizzate

### Frontend
- **Next.js 14** (App Router)
- **React 18** con TypeScript
- **Tailwind CSS** per lo styling
- **FullCalendar** per la visualizzazione calendario
- **React Hook Form** per la gestione form
- **Lucide React** per le icone

### Backend
- **Next.js API Routes**
- **PostgreSQL** database
- **Prisma** ORM
- **JWT** per autenticazione
- **bcryptjs** per hashing password
- **Zod** per validazione dati

## Setup del Progetto

### Prerequisiti
- Node.js 18+
- PostgreSQL database
- npm o yarn

### Installazione

1. **Clone il repository**
   ```bash
   git clone <repository-url>
   cd calendariko
   ```

2. **Installa le dipendenze**
   ```bash
   npm install
   ```

3. **Configura le variabili d'ambiente**
   
   Copia `.env.local` e modifica i valori:
   ```bash
   # Database
   DATABASE_URL="postgresql://username:password@localhost:5432/calendariko"
   
   # Auth
   NEXTAUTH_URL="http://localhost:3000"
   NEXTAUTH_SECRET="your-secret-key-here"
   JWT_SECRET="your-jwt-secret-here"
   
   # Email (per notifiche)
   SMTP_HOST="smtp.gmail.com"
   SMTP_PORT=587
   SMTP_USER="your-email@gmail.com"
   SMTP_PASS="your-app-password"
   ```

4. **Setup database**
   ```bash
   # Genera il client Prisma
   npm run db:generate
   
   # Applica le migrazioni
   npm run db:push
   
   # Popola il database con dati demo
   npm run db:seed
   ```

5. **Avvia il server di sviluppo**
   ```bash
   npm run dev
   ```

6. **Apri il browser**
   
   Vai su [http://localhost:3000](http://localhost:3000)

## Account Demo

Dopo aver eseguito il seed del database, puoi utilizzare questi account:

- **Admin**: `admin@calendariko.com` / `admin123`
- **Manager 1**: `manager1@example.com` / `manager123`
- **Manager 2**: `manager2@example.com` / `manager123`
- **Member 1**: `member1@example.com` / `member123`
- **Member 2**: `member2@example.com` / `member123`

## Struttura del Database

### Modelli Principali
- **User**: Utenti del sistema con ruoli
- **Band**: Gruppi musicali
- **UserBand**: Relazione many-to-many con ruoli
- **Event**: Eventi del calendario
- **Venue**: Locali e location
- **Tag**: Etichette per categorizzare eventi
- **Attachment**: File allegati agli eventi
- **AuditLog**: Log delle operazioni

### Tipi di Evento
- `CONCERTO`: Concerti pubblici con venue e cachet
- `INDISPONIBILITA`: Blocchi privati per indisponibilità
- `BLOCCO_AGENZIA`: Blocchi riservati all'agenzia

### Stati Evento
- `TENTATIVO`: Evento non ancora confermato
- `OPZIONE`: In attesa di conferma
- `CONFERMATO`: Evento confermato
- `ANNULLATO`: Evento cancellato

## API Endpoints

### Autenticazione
- `POST /api/auth/login` - Login utente
- `POST /api/auth/refresh` - Rinnova token
- `GET /api/auth/me` - Info utente corrente

### Band
- `GET /api/bands` - Lista band (filtrata per permessi)
- `POST /api/bands` - Crea nuova band (admin)
- `GET /api/bands/[id]` - Dettagli band
- `PATCH /api/bands/[id]` - Aggiorna band (admin)
- `DELETE /api/bands/[id]` - Elimina band (admin)

### Eventi
- `GET /api/events` - Lista eventi con filtri
- `POST /api/events` - Crea nuovo evento
- `GET /api/events/[id]` - Dettagli evento
- `PATCH /api/events/[id]` - Aggiorna evento
- `DELETE /api/events/[id]` - Elimina evento

## Modello di Permessi

### Admin (Agenzia)
- ✅ Vedere calendario tutte le band
- ✅ Vedere calendario propria band  
- ✅ Creare/Modificare eventi di tutte le band
- ✅ Eliminare eventi di tutte le band
- ✅ Creare/Modificare utenti e band
- ✅ Impostazioni globali

### Manager Band
- ❌ Vedere calendario tutte le band
- ✅ Vedere calendario propria band
- ✅ Creare/Modificare eventi della propria band
- ✅ Eliminare eventi della propria band  
- ✅ Creare/Modificare utenti della band
- ❌ Creare/Modificare altre band

### Member Band
- ❌ Vedere calendario tutte le band
- ✅ Vedere calendario propria band
- ✅ Creare/Modificare eventi della propria band
- ✅ Eliminare propri eventi (configurabile)
- ❌ Gestire utenti

## Sicurezza

### Autenticazione
- JWT con access token (15m) e refresh token (7d)
- Password hashate con bcryptjs
- Rate limiting per API

### Autorizzazione
- Controllo permessi a livello di API
- Filtraggio dati basato su ruoli
- Privacy events (BAND/AGENZIA)

### Validazione
- Zod schema validation
- Sanitizzazione input
- Controllo conflitti di calendario

## Deploy in Produzione

### Opzioni di Deploy
1. **Vercel** (consigliato per Next.js)
2. **Railway** / **Render**
3. **Docker** su VPS

### Configurazione Produzione
- Configurare DATABASE_URL per PostgreSQL produzione
- Impostare JWT_SECRET sicuro
- Configurare SMTP per notifiche email
- Abilitare HTTPS
- Configurare backup database

## Roadmap

### Fase 1 (MVP) ✅
- [x] Autenticazione e autorizzazione
- [x] Gestione band e utenti
- [x] Calendar con CRUD eventi
- [x] Filtri e ricerca
- [x] Mobile responsive
- [x] PWA basic

### Fase 2 (In Sviluppo)
- [ ] Sistema allegati
- [ ] Export iCal
- [ ] Notifiche email
- [ ] Tag e categorie avanzate
- [ ] Gestione conflitti avanzata

### Fase 3 (Futuro)
- [ ] Sync Google/Microsoft Calendar
- [ ] Notifiche push
- [ ] Sistema approvazioni
- [ ] Reportistica e analytics
- [ ] Multi-lingua completo
- [ ] Gestione finanziaria avanzata

## Contribuire

1. Fork del repository
2. Crea branch feature (`git checkout -b feature/nome-feature`)
3. Commit delle modifiche (`git commit -am 'Aggiunge nuova feature'`)
4. Push del branch (`git push origin feature/nome-feature`)
5. Apri una Pull Request

## Licenza

Questo progetto è rilasciato sotto licenza MIT. Vedi il file `LICENSE` per i dettagli.

## Supporto

Per bug reports e richieste di feature, apri un issue su GitHub.

---

**Calendariko** - Sistema professionale di gestione calendario per il mondo della musica 🎵