import { NextRequest, NextResponse } from 'next/server'

export async function PUT(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    // Temporary implementation to avoid build errors
    return NextResponse.json({
      success: false,
      message: 'Referente endpoint temporarily disabled'
    }, { status: 503 })
  } catch (error) {
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}