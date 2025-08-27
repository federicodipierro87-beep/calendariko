import { NextRequest, NextResponse } from 'next/server'
import { requireAuth } from '@/lib/middleware'
import { prisma } from '@/lib/prisma'
import { z } from 'zod'
import bcrypt from 'bcryptjs'

const updateUserSchema = z.object({
  name: z.string().min(1, 'Nome è richiesto').optional(),
  email: z.string().email('Email non valida').optional(),
  password: z.string().min(6, 'Password deve essere almeno 6 caratteri').optional(),
  isAdmin: z.boolean().optional(),
  bandIds: z.array(z.string()).optional(),
})

export async function PATCH(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const user = await requireAuth(request)
    
    // Only admins can update users
    if (!user.isAdmin) {
      return NextResponse.json(
        { error: 'Insufficient permissions' },
        { status: 403 }
      )
    }

    const body = await request.json()
    const data = updateUserSchema.parse(body)
    const userId = params.id

    // Check if user exists
    const existingUser = await prisma.user.findUnique({
      where: { id: userId }
    })

    if (!existingUser) {
      return NextResponse.json(
        { error: 'User not found' },
        { status: 404 }
      )
    }

    // Check email uniqueness if email is being updated
    if (data.email && data.email !== existingUser.email) {
      const emailExists = await prisma.user.findUnique({
        where: { email: data.email }
      })

      if (emailExists) {
        return NextResponse.json(
          { error: 'Email already exists' },
          { status: 400 }
        )
      }
    }

    // Prepare update data
    const updateData: any = {}
    if (data.name) updateData.name = data.name
    if (data.email) updateData.email = data.email
    if (data.isAdmin !== undefined) updateData.isAdmin = data.isAdmin
    if (data.password) {
      updateData.passwordHash = await bcrypt.hash(data.password, 12)
    }

    // Update user
    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data: updateData,
      include: {
        bands: {
          include: {
            band: true
          }
        }
      }
    })

    // Update band relationships if specified
    if (data.bandIds !== undefined) {
      // Remove existing band relationships
      await prisma.userBand.deleteMany({
        where: { userId }
      })

      // Create new band relationships
      if (data.bandIds.length > 0) {
        await prisma.userBand.createMany({
          data: data.bandIds.map(bandId => ({
            userId,
            bandId,
          }))
        })
      }
    }

    // Fetch complete updated user data
    const completeUser = await prisma.user.findUnique({
      where: { id: userId },
      include: {
        bands: {
          include: {
            band: true
          }
        }
      }
    })

    const transformedUser = {
      ...completeUser,
      bands: completeUser?.bands.map(ub => ub.band) || []
    }

    return NextResponse.json({
      success: true,
      data: transformedUser
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

    console.error('Update user error:', error)
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
    
    // Only admins can delete users
    if (!user.isAdmin) {
      return NextResponse.json(
        { error: 'Insufficient permissions' },
        { status: 403 }
      )
    }

    const userId = params.id

    // Prevent self-deletion
    if (user.id === userId) {
      return NextResponse.json(
        { error: 'Cannot delete your own account' },
        { status: 400 }
      )
    }

    // Check if user exists
    const existingUser = await prisma.user.findUnique({
      where: { id: userId }
    })

    if (!existingUser) {
      return NextResponse.json(
        { error: 'User not found' },
        { status: 404 }
      )
    }

    // Delete user (this will cascade delete related records)
    await prisma.user.delete({
      where: { id: userId }
    })

    return NextResponse.json({
      success: true,
      message: 'User deleted successfully'
    })
  } catch (error) {
    if (error instanceof NextResponse) {
      return error
    }

    console.error('Delete user error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}