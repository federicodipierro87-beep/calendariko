import { NextRequest, NextResponse } from 'next/server'
import { AuthService } from './auth'
import { prisma } from './prisma'

export interface AuthenticatedRequest extends NextRequest {
  user?: {
    id: string
    email: string
    name: string
    isAdmin: boolean
    bands: Array<{
      id: string
      name: string
      role: string
    }>
  }
}

export async function authenticateRequest(request: NextRequest): Promise<{
  authenticated: boolean
  user?: AuthenticatedRequest['user']
  response?: NextResponse
}> {
  const authHeader = request.headers.get('authorization')
  const token = AuthService.extractTokenFromHeader(authHeader || undefined)

  if (!token) {
    return {
      authenticated: false,
      response: NextResponse.json({ error: 'Authentication required' }, { status: 401 })
    }
  }

  const payload = AuthService.verifyToken(token)
  if (!payload) {
    return {
      authenticated: false,
      response: NextResponse.json({ error: 'Invalid token' }, { status: 401 })
    }
  }

  try {
    // Get user with bands
    const user = await prisma.user.findUnique({
      where: { id: payload.userId },
      include: {
        bands: {
          include: {
            band: true
          }
        }
      }
    })

    if (!user) {
      return {
        authenticated: false,
        response: NextResponse.json({ error: 'User not found' }, { status: 401 })
      }
    }

    return {
      authenticated: true,
      user: {
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
    }
  } catch (error) {
    console.error('Authentication error:', error)
    return {
      authenticated: false,
      response: NextResponse.json({ error: 'Authentication failed' }, { status: 500 })
    }
  }
}

export async function requireAuth(request: NextRequest) {
  const auth = await authenticateRequest(request)
  if (!auth.authenticated) {
    throw auth.response
  }
  return auth.user!
}

export async function requireAdmin(request: NextRequest) {
  const user = await requireAuth(request)
  if (!user.isAdmin) {
    throw NextResponse.json({ error: 'Admin access required' }, { status: 403 })
  }
  return user
}