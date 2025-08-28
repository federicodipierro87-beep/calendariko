import { NextRequest, NextResponse } from 'next/server'

export async function POST(request: NextRequest) {
  try {
    // Temporary implementation to avoid build errors
    return NextResponse.json({
      success: false,
      message: 'Login endpoint temporarily disabled'
    }, { status: 503 })
  } catch (error) {
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}