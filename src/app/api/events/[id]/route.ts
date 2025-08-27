import { NextRequest, NextResponse } from 'next/server'
import { requireAuth } from '@/lib/middleware'
import { PermissionService } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { emailService } from '@/lib/email'
import { z } from 'zod'
import { EventType, EventStatus, EventPrivacy } from '@prisma/client'

const updateEventSchema = z.object({
  bandId: z.string().optional(),
  type: z.nativeEnum(EventType).optional(),
  title: z.string().min(1).optional(),
  start: z.string().datetime().optional(),
  end: z.string().datetime().optional(),
  allDay: z.boolean().optional(),
  status: z.nativeEnum(EventStatus).optional(),
  privacy: z.nativeEnum(EventPrivacy).optional(),
  notes: z.string().optional(),
  venueId: z.string().optional(),
  venueName: z.string().optional(),
  venueAddress: z.string().optional(),
  venueCity: z.string().optional(),
  venueCountry: z.string().optional(),
  cachet: z.number().optional(),
  acconto: z.number().optional(),
  spese: z.number().optional(),
  valuta: z.string().optional(),
  tagIds: z.array(z.string()).optional(),
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

export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const user = await requireAuth(request)
    const { id } = params

    const event = await prisma.event.findUnique({
      where: { id },
      include: {
        band: true,
        creator: {
          select: { id: true, name: true, email: true }
        },
        updater: {
          select: { id: true, name: true, email: true }
        },
        venue: {
          include: { venue: true }
        },
        tags: {
          include: { tag: true }
        },
        attachments: true,
        _count: {
          select: { attachments: true }
        }
      }
    })

    if (!event) {
      return NextResponse.json(
        { error: 'Event not found' },
        { status: 404 }
      )
    }

    // Check permissions
    if (!PermissionService.canViewBand(user, event.bandId)) {
      return NextResponse.json(
        { error: 'Insufficient permissions' },
        { status: 403 }
      )
    }

    // Apply privacy rules
    const canViewFinancials = PermissionService.canViewEventFinancials(user, {
      bandId: event.bandId,
      privacy: event.privacy
    })

    const canEdit = PermissionService.canEditEvent(user, event)
    const canDelete = PermissionService.canDeleteEvent(user, event)

    const transformedEvent = {
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

    return NextResponse.json({
      success: true,
      data: transformedEvent
    })
  } catch (error) {
    if (error instanceof NextResponse) {
      return error
    }

    console.error('Get event error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}

export async function PATCH(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const user = await requireAuth(request)
    const { id } = params

    // Get existing event
    const existingEvent = await prisma.event.findUnique({
      where: { id },
      include: { band: true }
    })

    if (!existingEvent) {
      return NextResponse.json(
        { error: 'Event not found' },
        { status: 404 }
      )
    }

    // Check permissions
    if (!PermissionService.canEditEvent(user, existingEvent)) {
      return NextResponse.json(
        { error: 'Insufficient permissions' },
        { status: 403 }
      )
    }

    const body = await request.json()
    const updateData = updateEventSchema.parse(body)

    // Validate dates if provided
    if (updateData.start && updateData.end) {
      const startDate = new Date(updateData.start)
      const endDate = new Date(updateData.end)
      
      if (endDate <= startDate) {
        return NextResponse.json(
          { error: 'End date must be after start date' },
          { status: 400 }
        )
      }
    }

    // Check for conflicts if dates are being changed
    if (updateData.start || updateData.end) {
      const startDate = updateData.start ? new Date(updateData.start) : existingEvent.start
      const endDate = updateData.end ? new Date(updateData.end) : existingEvent.end
      const bandId = updateData.bandId || existingEvent.bandId

      const conflicts = await prisma.event.findMany({
        where: {
          id: { not: id }, // Exclude current event
          bandId,
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
    }

    // Handle venue updates
    let venueId = updateData.venueId
    if (updateData.venueName && !venueId) {
      // Create new venue if name provided but no ID
      const venue = await prisma.venue.create({
        data: {
          name: updateData.venueName,
          address: updateData.venueAddress,
          city: updateData.venueCity,
          country: updateData.venueCountry || 'IT',
        }
      })
      venueId = venue.id
    }

    // Prepare update data (exclude venue and tag fields)
    const { venueId: _venueId, venueName, venueAddress, venueCity, venueCountry, tagIds, ...eventUpdateData } = updateData

    // Update event
    const event = await prisma.event.update({
      where: { id },
      data: {
        ...eventUpdateData,
        updatedBy: user.id,
      },
      include: {
        band: true,
        creator: {
          select: { id: true, name: true, email: true }
        },
        updater: {
          select: { id: true, name: true, email: true }
        }
      }
    })

    // Update venue relationship
    if (venueId) {
      await prisma.eventVenue.upsert({
        where: { eventId: id },
        create: {
          eventId: id,
          venueId,
        },
        update: {
          venueId,
        }
      })
    } else if (venueName === '' || venueName === null) {
      // Remove venue if name is explicitly cleared
      await prisma.eventVenue.deleteMany({
        where: { eventId: id }
      })
    }

    // Update tag relationships
    if (tagIds !== undefined) {
      // Remove existing tags
      await prisma.eventTag.deleteMany({
        where: { eventId: id }
      })
      
      // Add new tags
      if (tagIds.length > 0) {
        await prisma.eventTag.createMany({
          data: tagIds.map(tagId => ({
            eventId: id,
            tagId,
          }))
        })
      }
    }

    // Create audit log
    await prisma.auditLog.create({
      data: {
        entity: 'Event',
        entityId: id,
        action: 'UPDATE',
        actorId: user.id,
        metadata: {
          title: event.title,
          changes: Object.keys(eventUpdateData)
        }
      }
    })

    // Fetch complete updated event
    const completeEvent = await prisma.event.findUnique({
      where: { id },
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
        updater: {
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
      await sendEventNotificationToReferente(completeEvent, true)
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
      return NextResponse.json(
        { error: 'Invalid input data' },
        { status: 400 }
      )
    }

    console.error('Update event error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const user = await requireAuth(request)
    const { id } = params

    // Get existing event
    const existingEvent = await prisma.event.findUnique({
      where: { id },
      include: { band: true }
    })

    if (!existingEvent) {
      return NextResponse.json(
        { error: 'Event not found' },
        { status: 404 }
      )
    }

    // Check permissions
    if (!PermissionService.canDeleteEvent(user, existingEvent)) {
      return NextResponse.json(
        { error: 'Insufficient permissions' },
        { status: 403 }
      )
    }

    // Delete event (cascade will handle related records)
    await prisma.event.delete({
      where: { id }
    })

    // Create audit log
    await prisma.auditLog.create({
      data: {
        entity: 'Event',
        entityId: id,
        action: 'DELETE',
        actorId: user.id,
        metadata: {
          title: existingEvent.title,
          type: existingEvent.type,
          bandId: existingEvent.bandId
        }
      }
    })

    return NextResponse.json({
      success: true,
      message: 'Event deleted successfully'
    })
  } catch (error) {
    if (error instanceof NextResponse) {
      return error
    }

    console.error('Delete event error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}