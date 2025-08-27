# Guida al Deployment di Calendariko

## Opzione 1: Vercel (Consigliata)

### Prerequisiti
1. Account GitHub
2. Account Vercel (gratuito)
3. Database PostgreSQL online (es. Supabase, PlanetScale, o Neon)

### Step-by-step

#### 1. Preparare il repository
```bash
# Aggiungi tutto al git
git add .
git commit -m "Prepare for production deployment"
git push origin main
```

#### 2. Database di produzione
Scegli uno di questi provider gratuiti:

**Supabase (Consigliato)**
- Vai su https://supabase.com
- Crea nuovo progetto
- Ottieni la connection string da Settings > Database
- Formato: `postgresql://postgres:[YOUR-PASSWORD]@[PROJECT-REF].supabase.co:5432/postgres`

**Neon**
- Vai su https://neon.tech
- Crea database PostgreSQL gratuito
- Ottieni connection string

#### 3. Deploy su Vercel
1. Vai su https://vercel.com
2. Connetti il tuo repository GitHub
3. Aggiungi le variabili ambiente:
   - `DATABASE_URL`: La connection string del tuo database
   - `NEXTAUTH_SECRET`: Una chiave segreta forte (genera con: `openssl rand -base64 32`)
   - `JWT_SECRET`: Un'altra chiave segreta
   - `SMTP_HOST`: smtp.gmail.com
   - `SMTP_PORT`: 587
   - `SMTP_USER`: La tua email
   - `SMTP_PASS`: La tua app password Gmail

#### 4. Configurare il database
```bash
# Dopo il deploy, esegui le migrazioni
npx prisma migrate deploy
npx prisma generate
```

## Opzione 2: Railway

### 1. Database su Railway
1. Vai su https://railway.app
2. Crea nuovo progetto
3. Aggiungi servizio PostgreSQL
4. Ottieni connection string

### 2. Deploy dell'app
1. Connetti repository GitHub
2. Configura variabili ambiente
3. Deploy automatico

## Configurazione Email

### Gmail App Password
1. Vai su Google Account Settings
2. Security > 2-Step Verification
3. App passwords > Generate
4. Usa la password generata per SMTP_PASS

## Domini personalizzati

### Su Vercel
1. Vai su Project Settings > Domains
2. Aggiungi il tuo dominio
3. Configura DNS come indicato

### Aggiornare l'URL nell'app
Cambia l'URL del calendario nelle email da localhost al tuo dominio:
```typescript
// In src/lib/email.ts
<a href="https://your-domain.vercel.app/dashboard">
```

## Sicurezza per Produzione

### 1. Genera nuove chiavi segrete
```bash
# Per NEXTAUTH_SECRET e JWT_SECRET
openssl rand -base64 32
```

### 2. Aggiorna CORS se necessario
Verifica che le configurazioni CORS permettano il tuo dominio.

### 3. SSL
Vercel fornisce SSL automaticamente. Per altri provider, assicurati che HTTPS sia abilitato.

## Testing

1. Testa tutte le funzionalità
2. Verifica invio email
3. Controlla database connections
4. Test su dispositivi mobili

## Monitoraggio

### Logs
- Vercel: Usa la dashboard per vedere i logs
- Railway: Logs integrati nella dashboard

### Database
- Supabase: Dashboard integrata
- Neon: Console web per monitoring

## Backup

Configura backup automatici del database:
- Supabase: Backup automatici inclusi
- Railway: Point-in-time recovery