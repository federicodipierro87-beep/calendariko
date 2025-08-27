import { NextRequest, NextResponse } from 'next/server'
import { requireAuth } from '@/lib/middleware'

export async function GET(request: NextRequest) {
  try {
    const user = await requireAuth(request)

    return NextResponse.json({
      success: true,
      data: user
    })
  } catch (error) {
    if (error instanceof NextResponse) {
      return error
    }

    console.error('Me endpoint error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}