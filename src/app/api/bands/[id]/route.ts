import { NextRequest, NextResponse } from 'next/server'
import { requireAuth } from '@/lib/middleware'
import { PermissionService } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { z } from 'zod'

const updateBandSchema = z.object({
  name: z.string().min(1).optional(),
  slug: z.string().min(1).optional(),
  notes: z.string().optional(),
})

export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const user = await requireAuth(request)
    const { id } = params

    // Check permissions
    if (!PermissionService.canViewBand(user, id)) {
      return NextResponse.json(
        { error: 'Insufficient permissions' },
        { status: 403 }
      )
    }

    const band = await prisma.band.findUnique({
      where: { id },
      include: {
        users: {
          include: {
            user: {
              select: { id: true, name: true, email: true }
            }
          }
        },
        _count: {
          select: { events: true }
        }
      }
    })

    if (!band) {
      return NextResponse.json(
        { error: 'Band not found' },
        { status: 404 }
      )
    }

    return NextResponse.json({
      success: true,
      data: band
    })
  } catch (error) {
    if (error instanceof NextResponse) {
      return error
    }

    console.error('Get band error:', error)
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

    if (!PermissionService.canManageUsers(user)) {
      return NextResponse.json(
        { error: 'Insufficient permissions' },
        { status: 403 }
      )
    }

    const body = await request.json()
    const updateData = updateBandSchema.parse(body)

    // Check if new slug is already taken (if provided)
    if (updateData.slug) {
      const existingBand = await prisma.band.findUnique({
        where: { slug: updateData.slug }
      })

      if (existingBand && existingBand.id !== id) {
        return NextResponse.json(
          { error: 'Band slug already exists' },
          { status: 409 }
        )
      }
    }

    const band = await prisma.band.update({
      where: { id },
      data: updateData,
      include: {
        users: {
          include: {
            user: {
              select: { id: true, name: true, email: true }
            }
          }
        },
        _count: {
          select: { events: true }
        }
      }
    })

    // Create audit log
    await prisma.auditLog.create({
      data: {
        entity: 'Band',
        entityId: band.id,
        action: 'UPDATE',
        actorId: user.id,
        metadata: updateData
      }
    })

    return NextResponse.json({
      success: true,
      data: band
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

    console.error('Update band error:', error)
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

    if (!PermissionService.canManageUsers(user)) {
      return NextResponse.json(
        { error: 'Insufficient permissions' },
        { status: 403 }
      )
    }

    // Check if band exists
    const band = await prisma.band.findUnique({
      where: { id },
      include: {
        _count: {
          select: { events: true }
        }
      }
    })

    if (!band) {
      return NextResponse.json(
        { error: 'Band not found' },
        { status: 404 }
      )
    }

    // Check if band has events
    if (band._count.events > 0) {
      return NextResponse.json(
        { error: 'Cannot delete band with existing events' },
        { status: 409 }
      )
    }

    await prisma.band.delete({
      where: { id }
    })

    // Create audit log
    await prisma.auditLog.create({
      data: {
        entity: 'Band',
        entityId: id,
        action: 'DELETE',
        actorId: user.id,
        metadata: { name: band.name }
      }
    })

    return NextResponse.json({
      success: true,
      message: 'Band deleted successfully'
    })
  } catch (error) {
    if (error instanceof NextResponse) {
      return error
    }

    console.error('Delete band error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}