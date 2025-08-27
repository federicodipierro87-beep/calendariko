import { PrismaClient } from '@prisma/client'
import bcrypt from 'bcryptjs'

const prisma = new PrismaClient()

async function main() {
  // Create admin user
  const adminPasswordHash = await bcrypt.hash('admin123', 10)
  const admin = await prisma.user.upsert({
    where: { email: 'admin@calendariko.com' },
    update: {},
    create: {
      email: 'admin@calendariko.com',
      passwordHash: adminPasswordHash,
      name: 'Admin User',
      isAdmin: true,
    },
  })

  // Create demo bands
  const band1 = await prisma.band.upsert({
    where: { slug: 'the-rockers' },
    update: {},
    create: {
      name: 'The Rockers',
      slug: 'the-rockers',
      notes: 'Rock band from Milano',
    },
  })

  const band2 = await prisma.band.upsert({
    where: { slug: 'jazz-collective' },
    update: {},
    create: {
      name: 'Jazz Collective',
      slug: 'jazz-collective',
      notes: 'Jazz ensemble from Roma',
    },
  })

  const band3 = await prisma.band.upsert({
    where: { slug: 'electronic-duo' },
    update: {},
    create: {
      name: 'Electronic Duo',
      slug: 'electronic-duo',
      notes: 'Electronic music duo from Torino',
    },
  })

  // Create demo users
  const managerPasswordHash = await bcrypt.hash('manager123', 10)
  const manager1 = await prisma.user.upsert({
    where: { email: 'manager1@example.com' },
    update: {},
    create: {
      email: 'manager1@example.com',
      passwordHash: managerPasswordHash,
      name: 'Marco Rossi',
      isAdmin: false,
    },
  })

  const manager2 = await prisma.user.upsert({
    where: { email: 'manager2@example.com' },
    update: {},
    create: {
      email: 'manager2@example.com',
      passwordHash: managerPasswordHash,
      name: 'Giulia Bianchi',
      isAdmin: false,
    },
  })

  const memberPasswordHash = await bcrypt.hash('member123', 10)
  const member1 = await prisma.user.upsert({
    where: { email: 'member1@example.com' },
    update: {},
    create: {
      email: 'member1@example.com',
      passwordHash: memberPasswordHash,
      name: 'Luca Verdi',
      isAdmin: false,
    },
  })

  const member2 = await prisma.user.upsert({
    where: { email: 'member2@example.com' },
    update: {},
    create: {
      email: 'member2@example.com',
      passwordHash: memberPasswordHash,
      name: 'Anna Neri',
      isAdmin: false,
    },
  })

  // Assign users to bands
  await prisma.userBand.upsert({
    where: {
      userId_bandId: {
        userId: manager1.id,
        bandId: band1.id,
      },
    },
    update: {},
    create: {
      userId: manager1.id,
      bandId: band1.id,
      role: 'MANAGER',
    },
  })

  await prisma.userBand.upsert({
    where: {
      userId_bandId: {
        userId: member1.id,
        bandId: band1.id,
      },
    },
    update: {},
    create: {
      userId: member1.id,
      bandId: band1.id,
      role: 'MEMBER',
    },
  })

  await prisma.userBand.upsert({
    where: {
      userId_bandId: {
        userId: manager2.id,
        bandId: band2.id,
      },
    },
    update: {},
    create: {
      userId: manager2.id,
      bandId: band2.id,
      role: 'MANAGER',
    },
  })

  await prisma.userBand.upsert({
    where: {
      userId_bandId: {
        userId: member2.id,
        bandId: band2.id,
      },
    },
    update: {},
    create: {
      userId: member2.id,
      bandId: band2.id,
      role: 'MEMBER',
    },
  })

  // Create demo venues
  const venue1 = await prisma.venue.upsert({
    where: { id: 'venue-1' },
    update: {},
    create: {
      id: 'venue-1',
      name: 'Circolo Magnolia',
      address: 'Via Circonvallazione Idroscalo',
      city: 'Milano',
      country: 'IT',
      lat: 45.4354,
      lng: 9.2859,
    },
  })

  const venue2 = await prisma.venue.upsert({
    where: { id: 'venue-2' },
    update: {},
    create: {
      id: 'venue-2',
      name: 'Auditorium Parco della Musica',
      address: 'Viale Pietro de Coubertin, 30',
      city: 'Roma',
      country: 'IT',
      lat: 41.9234,
      lng: 12.4707,
    },
  })

  // Create default tags
  const tags = [
    { name: 'Festival', color: '#f59e0b' },
    { name: 'Club', color: '#8b5cf6' },
    { name: 'TV', color: '#ec4899' },
    { name: 'Promo', color: '#10b981' },
    { name: 'Tour', color: '#3b82f6' },
  ]

  for (const tagData of tags) {
    await prisma.tag.upsert({
      where: { name: tagData.name },
      update: {},
      create: tagData,
    })
  }

  // Create demo events
  const now = new Date()
  const nextWeek = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000)
  const nextMonth = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000)

  const event1 = await prisma.event.create({
    data: {
      bandId: band1.id,
      type: 'CONCERTO',
      title: 'Live @ Circolo Magnolia',
      start: new Date(nextWeek.setHours(21, 0, 0, 0)),
      end: new Date(nextWeek.setHours(23, 30, 0, 0)),
      status: 'CONFERMATO',
      privacy: 'BAND',
      notes: 'Soundcheck ore 18:00. Backline incluso.',
      createdBy: manager1.id,
      cachet: 2500.00,
      valuta: 'EUR',
    },
  })

  await prisma.eventVenue.create({
    data: {
      eventId: event1.id,
      venueId: venue1.id,
    },
  })

  const event2 = await prisma.event.create({
    data: {
      bandId: band2.id,
      type: 'CONCERTO',
      title: 'Jazz Night @ Auditorium',
      start: new Date(nextMonth.setHours(20, 0, 0, 0)),
      end: new Date(nextMonth.setHours(22, 0, 0, 0)),
      status: 'OPZIONE',
      privacy: 'BAND',
      notes: 'Concerto di beneficenza',
      createdBy: manager2.id,
      cachet: 3000.00,
      valuta: 'EUR',
    },
  })

  await prisma.eventVenue.create({
    data: {
      eventId: event2.id,
      venueId: venue2.id,
    },
  })

  // Create indisponibilità
  const unavailableDate = new Date(now.getTime() + 14 * 24 * 60 * 60 * 1000)
  await prisma.event.create({
    data: {
      bandId: band1.id,
      type: 'INDISPONIBILITA',
      title: 'Vacanze estive',
      start: new Date(unavailableDate.setHours(0, 0, 0, 0)),
      end: new Date(unavailableDate.setHours(23, 59, 59, 999)),
      allDay: true,
      status: 'CONFERMATO',
      privacy: 'BAND',
      notes: 'Band non disponibile',
      createdBy: manager1.id,
    },
  })

  console.log('Database seeded successfully!')
  console.log('Admin user: admin@calendariko.com / admin123')
  console.log('Manager 1: manager1@example.com / manager123')
  console.log('Manager 2: manager2@example.com / manager123')
  console.log('Member 1: member1@example.com / member123')
  console.log('Member 2: member2@example.com / member123')
}

main()
  .catch((e) => {
    console.error(e)
    process.exit(1)
  })
  .finally(async () => {
    await prisma.$disconnect()
  })