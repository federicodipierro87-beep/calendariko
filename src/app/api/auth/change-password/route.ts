import { NextRequest, NextResponse } from 'next/server'

export async function POST(request: NextRequest) {
  // Only enable in production with proper environment
  if (process.env.NODE_ENV !== 'production' || !process.env.DATABASE_URL) {
    return NextResponse.json({
      success: false,
      message: 'Change password endpoint temporarily disabled during build'
    }, { status: 503 })
  }

  try {
    // Dynamic import to avoid build issues
    const { authenticateRequest } = await import('@/lib/middleware')
    const { prisma } = await import('@/lib/prisma')
    const { z } = await import('zod')
    const bcrypt = await import('bcryptjs')

    const changePasswordSchema = z.object({
      currentPassword: z.string().min(1, 'Password attuale è richiesta'),
      newPassword: z.string().min(6, 'Nuova password deve essere almeno 6 caratteri'),
    })

    const auth = await authenticateRequest(request)
    if (!auth.authenticated) {
      return auth.response || NextResponse.json(
        { error: 'Authentication required' },
        { status: 401 }
      )
    }
    
    const user = auth.user!
    const body = await request.json()
    const data = changePasswordSchema.parse(body)

    // Get current user from database
    const currentUser = await prisma.user.findUnique({
      where: { id: user.id }
    })

    if (!currentUser) {
      return NextResponse.json(
        { error: 'User not found' },
        { status: 404 }
      )
    }

    // Verify current password
    const isCurrentPasswordValid = await bcrypt.compare(data.currentPassword, currentUser.passwordHash)
    if (!isCurrentPasswordValid) {
      return NextResponse.json(
        { error: 'Password attuale non corretta' },
        { status: 400 }
      )
    }

    // Hash new password
    const hashedNewPassword = await bcrypt.hash(data.newPassword, 12)

    // Update password
    await prisma.user.update({
      where: { id: user.id },
      data: {
        passwordHash: hashedNewPassword
      }
    })

    return NextResponse.json({
      success: true,
      message: 'Password changed successfully'
    })
  } catch (error) {
    console.error('Change password error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}