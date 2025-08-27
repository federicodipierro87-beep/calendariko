import { UserRole, EventType, EventStatus, EventPrivacy } from '@prisma/client'

export interface User {
  id: string
  email: string
  name: string
  isAdmin: boolean
  createdAt: Date
  updatedAt: Date
  bands?: UserBand[]
}

export interface Band {
  _count: any
  id: string
  name: string
  slug: string
  notes?: string
  createdAt: Date
  updatedAt: Date
  users?: UserBand[]
  events?: Event[]
}

export interface UserBand {
  userId: string
  bandId: string
  role: UserRole
  user?: User
  band?: Band
}

export interface Event {
  id: string
  bandId: string
  type: EventType
  title: string
  start: Date
  end: Date
  allDay: boolean
  status: EventStatus
  privacy: EventPrivacy
  notes?: string
  createdBy: string
  updatedBy?: string
  createdAt: Date
  updatedAt: Date
  cachet?: number
  acconto?: number
  spese?: number
  valuta?: string
  band?: Band
  creator?: User
  updater?: User
  venue?: EventVenue
  attachments?: Attachment[]
  tags?: EventTag[]
}

export interface Venue {
  id: string
  name: string
  address?: string
  city?: string
  country?: string
  lat?: number
  lng?: number
}

export interface EventVenue {
  eventId: string
  venueId: string
  event?: Event
  venue?: Venue
}

export interface Attachment {
  id: string
  eventId: string
  filename: string
  mime: string
  size: number
  storageKey: string
  uploadedBy: string
  createdAt: Date
  event?: Event
  uploader?: User
}

export interface Tag {
  id: string
  name: string
  color: string
  events?: EventTag[]
}

export interface EventTag {
  eventId: string
  tagId: string
  event?: Event
  tag?: Tag
}

export interface AuditLog {
  id: string
  entity: string
  entityId: string
  action: string
  actorId: string
  metadata?: any
  createdAt: Date
  actor?: User
}

// API Response Types
export interface ApiResponse<T> {
  success: boolean
  data?: T
  error?: string
  message?: string
}

export interface PaginatedResponse<T> {
  success: boolean
  data: T[]
  pagination: {
    page: number
    limit: number
    total: number
    pages: number
  }
}

// Form Types
export interface CreateEventForm {
  bandId: string
  type: EventType
  title: string
  start: string // ISO string
  end: string // ISO string
  allDay: boolean
  status: EventStatus
  privacy: EventPrivacy
  notes?: string
  venueId?: string
  venueName?: string
  venueAddress?: string
  venueCity?: string
  venueCountry?: string
  cachet?: number
  acconto?: number
  spese?: number
  valuta?: string
  tagIds?: string[]
}

export interface UpdateEventForm extends Partial<CreateEventForm> {
  id: string
}

export interface CreateBandForm {
  name: string
  slug: string
  notes?: string
}

export interface UpdateBandForm extends Partial<CreateBandForm> {
  id: string
}

export interface CreateUserForm {
  email: string
  password: string
  name: string
  isAdmin?: boolean
  bandIds?: string[]
  roles?: { [bandId: string]: UserRole }
}

export interface UpdateUserForm extends Partial<Omit<CreateUserForm, 'password'>> {
  id: string
  newPassword?: string
}

// Filter Types
export interface EventFilters {
  bandIds?: string[]
  type?: EventType[]
  status?: EventStatus[]
  from?: string // ISO date
  to?: string // ISO date
  search?: string
  tagIds?: string[]
  venueIds?: string[]
}

export interface CalendarSettings {
  defaultView: 'month' | 'week' | 'day' | 'list'
  startTime: string // HH:mm
  endTime: string // HH:mm
  timezone: string
  weekStart: 0 | 1 | 2 | 3 | 4 | 5 | 6 // 0 = Sunday
}

// Authentication Types
export interface LoginCredentials {
  email: string
  password: string
}

export interface AuthUser {
  id: string
  email: string
  name: string
  isAdmin: boolean
  bands: Array<{
    id: string
    name: string
    role: UserRole
  }>
}

export interface JWTPayload {
  userId: string
  email: string
  isAdmin: boolean
  iat?: number
  exp?: number
}

// Notification Types
export interface NotificationSettings {
  emailEnabled: boolean
  pushEnabled: boolean
  eventCreated: boolean
  eventUpdated: boolean
  eventDeleted: boolean
  reminderHours: number[]
  quietHours: {
    start: string // HH:mm
    end: string // HH:mm
  }
}

// Calendar Event (for FullCalendar)
export interface CalendarEvent {
  id: string
  title: string
  start: string | Date
  end: string | Date
  allDay: boolean
  backgroundColor?: string
  borderColor?: string
  textColor?: string
  extendedProps: {
    type: EventType
    status: EventStatus
    privacy: EventPrivacy
    bandId: string
    bandName: string
    venue?: string
    notes?: string
    cachet?: number
    canEdit: boolean
    canDelete: boolean
  }
}

// Export Types
export interface ICalFeedParams {
  bandId?: string
  userId?: string
  token: string
}

export interface ExportParams {
  format: 'csv' | 'ical'
  bandIds?: string[]
  from?: string
  to?: string
  includePrivate?: boolean
}