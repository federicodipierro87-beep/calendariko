import { NextRequest, NextResponse } from 'next/server'
import { requireAuth } from '@/lib/middleware'
import { PermissionService } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { z } from 'zod'

const createBandSchema = z.object({
  name: z.string().min(1),
  slug: z.string().min(1),
  notes: z.string().optional(),
})

export async function GET(request: NextRequest) {
  try {
    const user = await requireAuth(request)

    let bands
    if (PermissionService.canViewAllBands(user)) {
      // Admin can see all bands
      bands = await prisma.band.findMany({
        include: {
          users: {
            include: {
              user: {
                select: { id: true, name: true, email: true }
              }
            }
          },
          _count: {
            select: { 
              events: true,
              users: true 
            }
          }
        },
        orderBy: { name: 'asc' }
      })
    } else {
      // Users can only see their bands
      const userBandIds = user.bands?.map(b => b.id) || []
      bands = await prisma.band.findMany({
        where: {
          id: { in: userBandIds }
        },
        include: {
          users: {
            include: {
              user: {
                select: { id: true, name: true, email: true }
              }
            }
          },
          _count: {
            select: { 
              events: true,
              users: true 
            }
          }
        },
        orderBy: { name: 'asc' }
      })
    }

    return NextResponse.json({
      success: true,
      data: bands
    })
  } catch (error) {
    if (error instanceof NextResponse) {
      return error
    }

    console.error('Get bands error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}

export async function POST(request: NextRequest) {
  try {
    const user = await requireAuth(request)

    if (!PermissionService.canManageUsers(user)) {
      return NextResponse.json(
        { error: 'Insufficient permissions' },
        { status: 403 }
      )
    }

    const body = await request.json()
    const { name, slug, notes } = createBandSchema.parse(body)

    // Check if slug is already taken
    const existingBand = await prisma.band.findUnique({
      where: { slug }
    })

    if (existingBand) {
      return NextResponse.json(
        { error: 'Band slug already exists' },
        { status: 409 }
      )
    }

    const band = await prisma.band.create({
      data: {
        name,
        slug,
        notes,
      },
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
        action: 'CREATE',
        actorId: user.id,
        metadata: { name, slug }
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

    console.error('Create band error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}