import jwt from 'jsonwebtoken'
import bcrypt from 'bcryptjs'
import { JWTPayload } from '@/types'

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key'
const JWT_EXPIRES_IN = '8h'
const REFRESH_TOKEN_EXPIRES_IN = '7d'

export class AuthService {
  static async hashPassword(password: string): Promise<string> {
    return bcrypt.hash(password, 10)
  }

  static async verifyPassword(password: string, hashedPassword: string): Promise<boolean> {
    return bcrypt.compare(password, hashedPassword)
  }

  static generateTokens(payload: JWTPayload) {
    const accessToken = jwt.sign(payload, JWT_SECRET, {
      expiresIn: JWT_EXPIRES_IN,
    })

    const refreshToken = jwt.sign(
      { ...payload, type: 'refresh' },
      JWT_SECRET,
      { expiresIn: REFRESH_TOKEN_EXPIRES_IN }
    )

    return { accessToken, refreshToken }
  }

  static verifyToken(token: string): JWTPayload | null {
    try {
      const decoded = jwt.verify(token, JWT_SECRET) as JWTPayload
      return decoded
    } catch (error) {
      return null
    }
  }

  static extractTokenFromHeader(authHeader?: string): string | null {
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return null
    }
    return authHeader.substring(7)
  }
}

// Permission checking utilities
export class PermissionService {
  static canViewAllBands(user: { isAdmin: boolean }): boolean {
    return user.isAdmin
  }

  static canViewBand(user: { isAdmin: boolean; bands?: Array<{ id: string }> }, bandId: string): boolean {
    if (user.isAdmin) return true
    return user.bands?.some(band => band.id === bandId) || false
  }

  static canManageBand(user: { isAdmin: boolean; bands?: Array<{ id: string; role: string }> }, bandId: string): boolean {
    if (user.isAdmin) return true
    const userBand = user.bands?.find(band => band.id === bandId)
    return userBand?.role === 'MANAGER'
  }

  static canCreateEvent(user: { isAdmin: boolean; bands?: Array<{ id: string }> }, bandId: string): boolean {
    if (user.isAdmin) return true
    return user.bands?.some(band => band.id === bandId) || false
  }

  static canEditEvent(user: { isAdmin: boolean; bands?: Array<{ id: string; role: string }> }, event: { bandId: string; createdBy: string }): boolean {
    if (user.isAdmin) return true
    
    // Can edit if user is in the band
    const userBand = user.bands?.find(band => band.id === event.bandId)
    if (!userBand) return false

    // Managers can edit all events in their band
    if (userBand.role === 'MANAGER') return true

    // Members can edit only their own events (configurable)
    return event.createdBy === (user as any).id
  }

  static canDeleteEvent(user: { isAdmin: boolean; bands?: Array<{ id: string; role: string }> }, event: { bandId: string; createdBy: string }): boolean {
    if (user.isAdmin) return true
    
    const userBand = user.bands?.find(band => band.id === event.bandId)
    if (!userBand) return false

    // Managers can delete all events in their band
    if (userBand.role === 'MANAGER') return true

    // Members can delete only their own events (configurable)
    return event.createdBy === (user as any).id
  }

  static canViewEventFinancials(user: { isAdmin: boolean; bands?: Array<{ id: string; role: string }> }, event: { bandId: string; privacy: string }): boolean {
    if (user.isAdmin) return true
    if (event.privacy === 'AGENZIA') return false

    const userBand = user.bands?.find(band => band.id === event.bandId)
    return userBand?.role === 'MANAGER'
  }

  static canManageUsers(user: { isAdmin: boolean }): boolean {
    return user.isAdmin
  }

  static canManageBandUsers(user: { isAdmin: boolean; bands?: Array<{ id: string; role: string }> }, bandId: string): boolean {
    if (user.isAdmin) return true
    const userBand = user.bands?.find(band => band.id === bandId)
    return userBand?.role === 'MANAGER'
  }
}