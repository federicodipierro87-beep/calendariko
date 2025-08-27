import { NextRequest, NextResponse } from 'next/server'

export async function GET(request: NextRequest) {
  try {
    // Temporary implementation to avoid build errors
    return NextResponse.json({
      success: false,
      message: 'Bands endpoint temporarily disabled'
    }, { status: 503 })
  } catch (error) {
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}

export async function POST(request: NextRequest) {
  try {
    // Temporary implementation to avoid build errors
    return NextResponse.json({
      success: false,
      message: 'Create band endpoint temporarily disabled'
    }, { status: 503 })
  } catch (error) {
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}