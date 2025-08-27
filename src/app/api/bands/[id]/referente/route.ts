import { NextRequest, NextResponse } from 'next/server'
import { requireAuth } from '@/lib/middleware'
import { prisma } from '@/lib/prisma'
import { z } from 'zod'

const setReferenteSchema = z.object({
  userId: z.string().nullable(),
})

export async function POST(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const user = await requireAuth(request)
    
    // Only admins can set referente
    if (!user.isAdmin) {
      return NextResponse.json(
        { error: 'Insufficient permissions' },
        { status: 403 }
      )
    }

    const body = await request.json()
    const { userId } = setReferenteSchema.parse(body)
    const bandId = params.id

    // Check if band exists
    const band = await prisma.band.findUnique({
      where: { id: bandId }
    })

    if (!band) {
      return NextResponse.json(
        { error: 'Band not found' },
        { status: 404 }
      )
    }

    // Start transaction to update roles
    await prisma.$transaction(async (prisma) => {
      // First, reset all users in this band to MEMBER role
      await prisma.userBand.updateMany({
        where: { bandId },
        data: { role: 'MEMBER' }
      })

      // If userId is provided, set that user as MANAGER (referente)
      if (userId) {
        // Check if user is actually in this band
        const userBand = await prisma.userBand.findUnique({
          where: {
            userId_bandId: {
              userId,
              bandId
            }
          }
        })

        if (!userBand) {
          throw new Error('User is not a member of this band')
        }

        // Set user as MANAGER (referente)
        await prisma.userBand.update({
          where: {
            userId_bandId: {
              userId,
              bandId
            }
          },
          data: { role: 'MANAGER' }
        })
      }
    })

    // Return updated band with users
    const updatedBand = await prisma.band.findUnique({
      where: { id: bandId },
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
      }
    })

    return NextResponse.json({
      success: true,
      data: updatedBand
    })
  } catch (error) {
    if (error instanceof NextResponse) {
      return error
    }

    if (error instanceof z.ZodError) {
      return NextResponse.json(
        { error: 'Invalid input data', details: error.errors },
        { status: 400 }
      )
    }

    console.error('Set referente error:', error)
    return NextResponse.json(
      { error: error instanceof Error ? error.message : 'Internal server error' },
      { status: 500 }
    )
  }
}