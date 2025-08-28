import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { AuthService } from '@/lib/auth'
import { z } from 'zod'

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
})

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { email, password } = loginSchema.parse(body)

    // Find user with bands
    const user = await prisma.user.findUnique({
      where: { email },
      include: {
        bands: {
          include: {
            band: true
          }
        }
      }
    })

    if (!user) {
      return NextResponse.json(
        { error: 'Invalid credentials' },
        { status: 401 }
      )
    }

    // Verify password
    const isValidPassword = await AuthService.verifyPassword(password, user.passwordHash)
    if (!isValidPassword) {
      return NextResponse.json(
        { error: 'Invalid credentials' },
        { status: 401 }
      )
    }

    // Generate tokens
    const payload = {
      userId: user.id,
      email: user.email,
      isAdmin: user.isAdmin,
    }
    const { accessToken, refreshToken } = AuthService.generateTokens(payload)

    // Return user data and tokens
    const userData = {
      id: user.id,
      email: user.email,
      name: user.name,
      isAdmin: user.isAdmin,
      bands: user.bands.map(ub => ({
        id: ub.band.id,
        name: ub.band.name,
        role: ub.role
      }))
    }

    return NextResponse.json({
      success: true,
      data: {
        user: userData,
        accessToken,
        refreshToken
      }
    })
  } catch (error) {
    console.error('Login error:', error)
    
    if (error instanceof z.ZodError) {
      return NextResponse.json(
        { error: 'Invalid input data' },
        { status: 400 }
      )
    }

    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}