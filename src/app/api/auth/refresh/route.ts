import { NextRequest, NextResponse } from 'next/server'
import { AuthService } from '@/lib/auth'
import { z } from 'zod'

const refreshSchema = z.object({
  refreshToken: z.string(),
})

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { refreshToken } = refreshSchema.parse(body)

    // Verify refresh token
    const payload = AuthService.verifyToken(refreshToken)
    if (!payload || (payload as any).type !== 'refresh') {
      return NextResponse.json(
        { error: 'Invalid refresh token' },
        { status: 401 }
      )
    }

    // Generate new tokens
    const newPayload = {
      userId: payload.userId,
      email: payload.email,
      isAdmin: payload.isAdmin,
    }
    const { accessToken, refreshToken: newRefreshToken } = AuthService.generateTokens(newPayload)

    return NextResponse.json({
      success: true,
      data: {
        accessToken,
        refreshToken: newRefreshToken
      }
    })
  } catch (error) {
    console.error('Refresh token error:', error)
    
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