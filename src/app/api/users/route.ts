import { NextRequest, NextResponse } from 'next/server'
import { requireAuth } from '@/lib/middleware'
import { prisma } from '@/lib/prisma'
import { z } from 'zod'
import bcrypt from 'bcryptjs'

const createUserSchema = z.object({
  name: z.string().min(1, 'Nome è richiesto'),
  email: z.string().email('Email non valida'),
  password: z.string().min(6, 'Password deve essere almeno 6 caratteri'),
  isAdmin: z.boolean().default(false),
  bandIds: z.array(z.string()).optional().default([]),
})

export async function GET(request: NextRequest) {
  try {
    const user = await requireAuth(request)
    
    // Only admins can list all users
    if (!user.isAdmin) {
      return NextResponse.json(
        { error: 'Insufficient permissions' },
        { status: 403 }
      )
    }

    const users = await prisma.user.findMany({
      include: {
        bands: {
          include: {
            band: true
          }
        },
        _count: {
          select: { bands: true }
        }
      },
      orderBy: { name: 'asc' }
    })

    // Transform the response to match expected format
    const transformedUsers = users.map(user => ({
      ...user,
      bands: user.bands.map(ub => ub.band)
    }))

    return NextResponse.json({
      success: true,
      data: transformedUsers
    })
  } catch (error) {
    if (error instanceof NextResponse) {
      return error
    }

    console.error('Get users error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}

export async function POST(request: NextRequest) {
  try {
    console.log('POST /api/users called')
    const user = await requireAuth(request)
    console.log('User authenticated:', user.id, user.email)
    
    // Only admins can create users
    if (!user.isAdmin) {
      return NextResponse.json(
        { error: 'Insufficient permissions' },
        { status: 403 }
      )
    }

    const body = await request.json()
    console.log('Request body:', body)
    const data = createUserSchema.parse(body)
    console.log('Validated data:', data)

    // Check if email already exists
    const existingUser = await prisma.user.findUnique({
      where: { email: data.email }
    })

    if (existingUser) {
      return NextResponse.json(
        { error: 'Email already exists' },
        { status: 400 }
      )
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(data.password, 12)

    // Create user
    const newUser = await prisma.user.create({
      data: {
        name: data.name,
        email: data.email,
        passwordHash: hashedPassword,
        isAdmin: data.isAdmin,
      },
      include: {
        bands: {
          include: {
            band: true
          }
        }
      }
    })

    // Create band relationships if specified
    if (data.bandIds && data.bandIds.length > 0) {
      await prisma.userBand.createMany({
        data: data.bandIds.map(bandId => ({
          userId: newUser.id,
          bandId,
        }))
      })
    }

    // Fetch complete user data
    const completeUser = await prisma.user.findUnique({
      where: { id: newUser.id },
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

    console.error('Create user error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}