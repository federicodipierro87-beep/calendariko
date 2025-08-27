import nodemailer from 'nodemailer'

interface EmailConfig {
  host: string
  port: number
  user: string
  pass: string
}

interface EventEmailData {
  to: string
  toName: string
  eventTitle: string
  eventType: string
  eventStatus: string
  eventStart: string
  eventEnd: string
  venue?: string
  notes?: string
  bandName: string
  isUpdate: boolean
}

class EmailService {
  private transporter: nodemailer.Transporter | null = null

  private async createTransporter() {
    if (this.transporter) {
      return this.transporter
    }

    const config: EmailConfig = {
      host: process.env.SMTP_HOST?.trim() || '',
      port: parseInt(process.env.SMTP_PORT || '587'),
      user: process.env.SMTP_USER?.trim() || '',
      pass: process.env.SMTP_PASS?.trim().replace(/\s/g, '') || '' // Remove all spaces
    }

    // Check if all required env vars are present
    if (!config.host || !config.user || !config.pass) {
      console.warn('Email configuration incomplete. Skipping email sending.')
      console.warn('Config status:', {
        host: !!config.host,
        user: !!config.user,
        pass: !!config.pass
      })
      return null
    }

    console.log('Email config:', {
      host: config.host,
      port: config.port,
      user: config.user,
      passLength: config.pass.length
    })

    this.transporter = nodemailer.createTransport({
      host: config.host,
      port: config.port,
      secure: config.port === 465, // true for 465, false for other ports
      auth: {
        user: config.user,
        pass: config.pass,
      },
    })

    return this.transporter
  }

  async sendEventNotification(data: EventEmailData): Promise<boolean> {
    try {
      const transporter = await this.createTransporter()
      if (!transporter) {
        console.log('Email transporter not configured, skipping email')
        return false
      }

      const subject = data.isUpdate 
        ? `Evento Modificato: ${data.eventTitle}` 
        : `Nuovo Evento: ${data.eventTitle}`

      const htmlContent = this.generateEventEmailHTML(data)
      const textContent = this.generateEventEmailText(data)

      const mailOptions = {
        from: {
          name: 'Calendariko',
          address: process.env.SMTP_USER || 'noreply@calendariko.com'
        },
        to: {
          name: data.toName,
          address: data.to
        },
        subject: subject,
        text: textContent,
        html: htmlContent,
      }

      const info = await transporter.sendMail(mailOptions)
      console.log('Email sent successfully:', info.messageId)
      return true

    } catch (error) {
      console.error('Error sending email:', error)
      return false
    }
  }

  private generateEventEmailHTML(data: EventEmailData): string {
    const formatDate = (dateStr: string) => {
      const date = new Date(dateStr)
      return date.toLocaleDateString('it-IT', {
        weekday: 'long',
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      })
    }

    const statusColor = {
      'OPZIONE': '#f59e0b',
      'CONFERMATO': '#10b981',
      'ANNULLATO': '#ef4444'
    }[data.eventStatus] || '#6b7280'

    const typeLabel = {
      'CONCERTO': 'Concerto',
      'INDISPONIBILITA': 'Indisponibilità',
      'BLOCCO_AGENZIA': 'Blocco Agenzia'
    }[data.eventType] || data.eventType

    const statusLabel = {
      'OPZIONE': 'Opzione',
      'CONFERMATO': 'Confermato',
      'ANNULLATO': 'Annullato'
    }[data.eventStatus] || data.eventStatus

    return `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>${data.isUpdate ? 'Evento Modificato' : 'Nuovo Evento'}</title>
      </head>
      <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
        <div style="background: #f8f9fa; padding: 20px; border-radius: 10px; margin-bottom: 20px;">
          <h1 style="color: #2563eb; margin: 0; font-size: 24px;">
            🎵 ${data.isUpdate ? 'Evento Modificato' : 'Nuovo Evento'}
          </h1>
        </div>

        <div style="background: white; padding: 20px; border-radius: 10px; border: 1px solid #e5e7eb;">
          <p style="margin-top: 0;">
            Ciao <strong>${data.toName}</strong>,
          </p>
          
          <p>
            ${data.isUpdate 
              ? 'È stato modificato un evento per la tua band'
              : 'È stato creato un nuovo evento per la tua band'
            } <strong>${data.bandName}</strong>:
          </p>

          <div style="background: #f8f9fa; padding: 15px; border-radius: 8px; margin: 20px 0;">
            <h2 style="margin: 0 0 15px 0; color: #1f2937; font-size: 20px;">
              ${data.eventTitle}
            </h2>
            
            <div style="display: grid; gap: 10px;">
              <div><strong>Tipo:</strong> ${typeLabel}</div>
              <div><strong>Stato:</strong> 
                <span style="background: ${statusColor}; color: white; padding: 2px 8px; border-radius: 12px; font-size: 12px;">
                  ${statusLabel}
                </span>
              </div>
              <div><strong>Inizio:</strong> ${formatDate(data.eventStart)}</div>
              <div><strong>Fine:</strong> ${formatDate(data.eventEnd)}</div>
              ${data.venue ? `<div><strong>Venue:</strong> ${data.venue}</div>` : ''}
              ${data.notes ? `<div><strong>Note:</strong> ${data.notes}</div>` : ''}
            </div>
          </div>

          <p style="margin-bottom: 0;">
            Puoi visualizzare tutti i dettagli dell'evento 
            <a href="${process.env.NEXTAUTH_URL}/dashboard" style="color: #2563eb; text-decoration: none; font-weight: bold;">
              accedendo al calendario
            </a>.
          </p>
        </div>

        <div style="text-align: center; margin-top: 30px; color: #6b7280; font-size: 14px;">
          <p>Questa email è stata generata automaticamente da Calendariko</p>
        </div>
      </body>
      </html>
    `
  }

  private generateEventEmailText(data: EventEmailData): string {
    const formatDate = (dateStr: string) => {
      const date = new Date(dateStr)
      return date.toLocaleDateString('it-IT', {
        weekday: 'long',
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      })
    }

    const typeLabel = {
      'CONCERTO': 'Concerto',
      'INDISPONIBILITA': 'Indisponibilità',
      'BLOCCO_AGENZIA': 'Blocco Agenzia'
    }[data.eventType] || data.eventType

    const statusLabel = {
      'OPZIONE': 'Opzione',
      'CONFERMATO': 'Confermato',
      'ANNULLATO': 'Annullato'
    }[data.eventStatus] || data.eventStatus

    return `
${data.isUpdate ? 'EVENTO MODIFICATO' : 'NUOVO EVENTO'}

Ciao ${data.toName},

${data.isUpdate 
  ? 'È stato modificato un evento per la tua band'
  : 'È stato creato un nuovo evento per la tua band'
} ${data.bandName}:

DETTAGLI EVENTO:
- Titolo: ${data.eventTitle}
- Tipo: ${typeLabel}
- Stato: ${statusLabel}
- Inizio: ${formatDate(data.eventStart)}
- Fine: ${formatDate(data.eventEnd)}
${data.venue ? `- Venue: ${data.venue}` : ''}
${data.notes ? `- Note: ${data.notes}` : ''}

Puoi visualizzare tutti i dettagli dell'evento accedendo al calendario.

---
Questa email è stata generata automaticamente da Calendariko
    `.trim()
  }
}

export const emailService = new EmailService()