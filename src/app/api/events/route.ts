import { NextRequest, NextResponse } from 'next/server'
import { requireAuth } from '@/lib/middleware'
import { PermissionService } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { emailService } from '@/lib/email'
import { z } from 'zod'
import { EventType, EventStatus, EventPrivacy } from '@prisma/client'

const createEventSchema = z.object({
  bandId: z.string(),
  type: z.nativeEnum(EventType),
  title: z.string().min(1),
  start: z.string().datetime(),
  end: z.string().datetime(),
  allDay: z.boolean().default(false),
  status: z.nativeEnum(EventStatus).default('TENTATIVO'),
  privacy: z.nativeEnum(EventPrivacy).default('BAND'),
  notes: z.string().optional(),
  venueId: z.string().optional(),
  venueName: z.string().optional(),
  venueAddress: z.string().optional(),
  venueCity: z.string().optional(),
  venueCountry: z.string().optional().default('IT'),
  cachet: z.number().optional(),
  acconto: z.number().optional(),
  spese: z.number().optional(),
  valuta: z.string().optional().default('EUR'),
  tagIds: z.array(z.string()).optional(),
})

const filterSchema = z.object({
  bandIds: z.string().optional().nullable(),
  type: z.string().optional().nullable(),
  status: z.string().optional().nullable(),
  from: z.string().optional().nullable(),
  to: z.string().optional().nullable(),
  search: z.string().optional().nullable(),
})

async function sendEventNotificationToReferente(event: any, isUpdate: boolean = false) {
  try {
    // Only send emails if user is admin
    const referente = event.band.users?.find((ub: any) => ub.role === 'MANAGER')
    
    if (!referente) {
      console.log('No referente found for band:', event.band.name)
      return
    }

    const emailData = {
      to: referente.user.email,
      toName: referente.user.name,
      eventTitle: event.title,
      eventType: event.type,
      eventStatus: event.status,
      eventStart: event.start.toISOString(),
      eventEnd: event.end.toISOString(),
      venue: event.venue?.venue?.name,
      notes: event.notes,
      bandName: event.band.name,
      isUpdate
    }

    await emailService.sendEventNotification(emailData)
  } catch (error) {
    console.error('Error sending event notification email:', error)
    // Don't throw - we don't want email failures to break event creation
  }
}

export async function GET(request: NextRequest) {
  try {
    console.log('GET /api/events called')
    const user = await requireAuth(request)
    console.log('User authenticated:', user.id, user.email)
    const { searchParams } = new URL(request.url)
    
    const filters = filterSchema.parse({
      bandIds: searchParams.get('bandIds'),
      type: searchParams.get('type'),
      status: searchParams.get('status'),
      from: searchParams.get('from'),
      to: searchParams.get('to'),
      search: searchParams.get('search'),
    })

    // Build where clause
    const where: any = {}

    // Band filtering based on permissions
    if (user.isAdmin) {
      if (filters.bandIds) {
        const bandIds = filters.bandIds.split(',')
        where.bandId = { in: bandIds }
      }
    } else {
      // Non-admin users can only see events from their bands
      const userBandIds = user.bands?.map(b => b.id) || []
      if (filters.bandIds) {
        const requestedBandIds = filters.bandIds.split(',')
        const allowedBandIds = requestedBandIds.filter(id => userBandIds.includes(id))
        where.bandId = { in: allowedBandIds }
      } else {
        where.bandId = { in: userBandIds }
      }
    }

    // Other filters
    if (filters.type) {
      where.type = { in: filters.type.split(',') }
    }
    if (filters.status) {
      where.status = { in: filters.status.split(',') }
    }
    if (filters.from || filters.to) {
      where.start = {}
      if (filters.from) {
        where.start.gte = new Date(filters.from)
      }
      if (filters.to) {
        where.start.lte = new Date(filters.to)
      }
    }
    if (filters.search) {
      where.OR = [
        { title: { contains: filters.search, mode: 'insensitive' } },
        { notes: { contains: filters.search, mode: 'insensitive' } },
      ]
    }

    const events = await prisma.event.findMany({
      where,
      include: {
        band: true,
        creator: {
          select: { id: true, name: true, email: true }
        },
        venue: {
          include: { venue: true }
        },
        tags: {
          include: { tag: true }
        },
        _count: {
          select: { attachments: true }
        }
      },
      orderBy: { start: 'asc' }
    })

    // Transform events for response, applying privacy rules
    const transformedEvents = events.map(event => {
      const canViewFinancials = PermissionService.canViewEventFinancials(user, {
        bandId: event.bandId,
        privacy: event.privacy
      })

      const canEdit = PermissionService.canEditEvent(user, event)
      const canDelete = PermissionService.canDeleteEvent(user, event)

      return {
        ...event,
        // Hide financial data if user doesn't have permission
        cachet: canViewFinancials ? event.cachet : undefined,
        acconto: canViewFinancials ? event.acconto : undefined,
        spese: canViewFinancials ? event.spese : undefined,
        valuta: canViewFinancials ? event.valuta : undefined,
        // Add permission flags
        canEdit,
        canDelete,
      }
    })

    return NextResponse.json({
      success: true,
      data: transformedEvents
    })
  } catch (error) {
    if (error instanceof NextResponse) {
      return error
    }

    if (error instanceof z.ZodError) {
      return NextResponse.json(
        { error: 'Invalid filter parameters' },
        { status: 400 }
      )
    }

    console.error('Get events error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}

export async function POST(request: NextRequest) {
  try {
    const user = await requireAuth(request)
    const body = await request.json()
    const data = createEventSchema.parse(body)

    // Check permissions
    if (!PermissionService.canCreateEvent(user, data.bandId)) {
      return NextResponse.json(
        { error: 'Insufficient permissions' },
        { status: 403 }
      )
    }

    // Validate dates
    const startDate = new Date(data.start)
    const endDate = new Date(data.end)
    
    if (endDate <= startDate) {
      return NextResponse.json(
        { error: 'End date must be after start date' },
        { status: 400 }
      )
    }

    // Check for conflicts with existing events (same band)
    const conflicts = await prisma.event.findMany({
      where: {
        bandId: data.bandId,
        OR: [
          {
            start: { lte: endDate },
            end: { gte: startDate }
          }
        ]
      },
      include: { band: true }
    })

    if (conflicts.length > 0) {
      return NextResponse.json(
        {
          error: 'Schedule conflict detected',
          conflicts: conflicts.map(c => ({
            id: c.id,
            title: c.title,
            start: c.start,
            end: c.end,
            type: c.type
          }))
        },
        { status: 409 }
      )
    }

    // Handle venue creation if needed
    let venueId = data.venueId
    if (!venueId && data.venueName) {
      const venue = await prisma.venue.create({
        data: {
          name: data.venueName,
          address: data.venueAddress,
          city: data.venueCity,
          country: data.venueCountry || 'IT',
        }
      })
      venueId = venue.id
    }

    // Create event
    const event = await prisma.event.create({
      data: {
        bandId: data.bandId,
        type: data.type,
        title: data.title,
        start: startDate,
        end: endDate,
        allDay: data.allDay,
        status: data.status,
        privacy: data.privacy,
        notes: data.notes,
        createdBy: user.id,
        cachet: data.cachet,
        acconto: data.acconto,
        spese: data.spese,
        valuta: data.valuta,
      },
      include: {
        band: true,
        creator: {
          select: { id: true, name: true, email: true }
        }
      }
    })

    // Create venue relationship if venue exists
    if (venueId) {
      await prisma.eventVenue.create({
        data: {
          eventId: event.id,
          venueId,
        }
      })
    }

    // Create tag relationships
    if (data.tagIds && data.tagIds.length > 0) {
      await prisma.eventTag.createMany({
        data: data.tagIds.map(tagId => ({
          eventId: event.id,
          tagId,
        }))
      })
    }

    // Create audit log
    await prisma.auditLog.create({
      data: {
        entity: 'Event',
        entityId: event.id,
        action: 'CREATE',
        actorId: user.id,
        metadata: {
          title: event.title,
          type: event.type,
          bandId: event.bandId
        }
      }
    })

    // Fetch complete event data
    const completeEvent = await prisma.event.findUnique({
      where: { id: event.id },
      include: {
        band: {
          include: {
            users: {
              include: {
                user: {
                  select: { id: true, name: true, email: true }
                }
              }
            }
          }
        },
        creator: {
          select: { id: true, name: true, email: true }
        },
        venue: {
          include: { venue: true }
        },
        tags: {
          include: { tag: true }
        },
        _count: {
          select: { attachments: true }
        }
      }
    })

    // Send email to referente if user is admin
    if (user.isAdmin && completeEvent) {
      await sendEventNotificationToReferente(completeEvent, false)
    }

    return NextResponse.json({
      success: true,
      data: completeEvent
    })
  } catch (error) {
    if (error instanceof NextResponse) {
      return error
    }

    if (error instanceof z.ZodError) {
      console.error('Validation errors:', error.errors)
      return NextResponse.json(
        { error: 'Invalid input data', details: error.errors },
        { status: 400 }
      )
    }

    console.error('Create event error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}