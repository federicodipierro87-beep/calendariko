'use client'

import { useEffect, useState } from 'react'
import FullCalendar from '@fullcalendar/react'
import dayGridPlugin from '@fullcalendar/daygrid'
import timeGridPlugin from '@fullcalendar/timegrid'
import interactionPlugin from '@fullcalendar/interaction'
import { AuthUser, CalendarEvent, Event, Band } from '@/types'
import EventModal from './EventModal'
import EventFilters from './EventFilters'
import LoadingSpinner from './LoadingSpinner'
import { Plus } from 'lucide-react'

interface CalendarProps {
  user: AuthUser
}

export default function Calendar({ user }: CalendarProps) {
  const [events, setEvents] = useState<Event[]>([])
  const [bands, setBands] = useState<Band[]>([])
  const [loading, setLoading] = useState(true)
  const [selectedEvent, setSelectedEvent] = useState<Event | null>(null)
  const [isEventModalOpen, setIsEventModalOpen] = useState(false)
  const [isCreating, setIsCreating] = useState(false)
  const [selectedDate, setSelectedDate] = useState<string | null>(null)
  const [filters, setFilters] = useState({
    bandIds: user.isAdmin ? [] : user.bands.map(b => b.id),
    type: [],
    status: [],
    search: '',
  })

  useEffect(() => {
    loadBands()
    loadEvents()
  }, [filters])

  const loadBands = async () => {
    try {
      const token = localStorage.getItem('accessToken')
      const response = await fetch('/api/bands', {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      })
      
      if (response.ok) {
        const result = await response.json()
        setBands(result.data)
      }
    } catch (error) {
      console.error('Error loading bands:', error)
    }
  }

  const loadEvents = async () => {
    try {
      setLoading(true)
      const token = localStorage.getItem('accessToken')
      
      const params = new URLSearchParams()
      if (filters.bandIds.length > 0) {
        params.set('bandIds', filters.bandIds.join(','))
      }
      if (filters.type.length > 0) {
        params.set('type', filters.type.join(','))
      }
      if (filters.status.length > 0) {
        params.set('status', filters.status.join(','))
      }
      if (filters.search) {
        params.set('search', filters.search)
      }

      const queryString = params.toString()
      const url = queryString ? `/api/events?${queryString}` : '/api/events'
      console.log('Fetching events from:', url)
      
      const response = await fetch(url, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      })
      
      if (response.ok) {
        const result = await response.json()
        setEvents(result.data)
      } else {
        const errorResult = await response.json()
        console.error('Error loading events:', response.status, errorResult)
      }
    } catch (error) {
      console.error('Error loading events:', error)
    } finally {
      setLoading(false)
    }
  }

  const transformEventsForCalendar = (events: Event[]): CalendarEvent[] => {
    return events.map(event => {
      const band = bands.find(b => b.id === event.bandId)
      
      // Ensure dates are in proper format for FullCalendar
      const startDate = new Date(event.start)
      const endDate = new Date(event.end)
      
      // For all-day events in week view, use date-only format
      let start, end
      if (event.allDay) {
        start = startDate.toISOString().split('T')[0] // YYYY-MM-DD
        end = endDate.toISOString().split('T')[0]     // YYYY-MM-DD
      } else {
        start = startDate.toISOString()
        end = endDate.toISOString()
      }
      
      const calendarEvent = {
        id: event.id,
        title: event.title,
        start: start,
        end: end,
        allDay: event.allDay,
        backgroundColor: getEventColor(event.type, event.status),
        borderColor: getEventBorderColor(event.type, event.status),
        textColor: '#ffffff',
        extendedProps: {
          type: event.type,
          status: event.status,
          privacy: event.privacy,
          bandId: event.bandId,
          bandName: band?.name || 'Unknown Band',
          venue: event.venue?.venue?.name,
          notes: event.notes,
          cachet: event.cachet,
          canEdit: (event as any).canEdit,
          canDelete: (event as any).canDelete,
        }
      }
      
      return calendarEvent
    })
  }

  const getEventColor = (type: string, status: string) => {
    if (status === 'ANNULLATO') return '#ef4444' // Rosso
    
    switch (type) {
      case 'CONCERTO':
        return status === 'CONFERMATO' ? '#10b981' : // Verde
               status === 'OPZIONE' ? '#f59e0b' : '#6b7280' // Arancione
      case 'INDISPONIBILITA':
        return '#6b7280' // Grigio
      case 'BLOCCO_AGENZIA':
        return '#8b5cf6' // Viola
      default:
        return '#6b7280'
    }
  }

  const getEventBorderColor = (type: string, status: string) => {
    if (status === 'ANNULLATO') return '#dc2626' // Rosso scuro
    
    switch (type) {
      case 'CONCERTO':
        return status === 'CONFERMATO' ? '#059669' : // Verde scuro
               status === 'OPZIONE' ? '#d97706' : '#4b5563' // Arancione scuro
      case 'INDISPONIBILITA':
        return '#4b5563' // Grigio scuro
      case 'BLOCCO_AGENZIA':
        return '#7c3aed' // Viola scuro
      default:
        return '#4b5563'
    }
  }

  const handleDateClick = (info: any) => {
    if (user.bands.length === 0 && !user.isAdmin) {
      alert('Non hai band assegnate. Contatta l\'amministratore.')
      return
    }
    
    setSelectedDate(info.dateStr)
    setSelectedEvent(null)
    setIsCreating(true)
    setIsEventModalOpen(true)
  }

  const handleEventClick = (info: any) => {
    const event = events.find(e => e.id === info.event.id)
    if (event) {
      setSelectedEvent(event)
      setIsCreating(false)
      setIsEventModalOpen(true)
    }
  }

  const handleEventSaved = () => {
    console.log('handleEventSaved called, reloading events...')
    loadEvents()
    setIsEventModalOpen(false)
    setSelectedEvent(null)
    setSelectedDate(null)
  }

  const handleCreateEvent = () => {
    if (user.bands.length === 0 && !user.isAdmin) {
      alert('Non hai band assegnate. Contatta l\'amministratore.')
      return
    }
    
    setSelectedEvent(null)
    setSelectedDate(new Date().toISOString().split('T')[0])
    setIsCreating(true)
    setIsEventModalOpen(true)
  }

  const calendarEvents = transformEventsForCalendar(events)

  if (loading && events.length === 0) {
    return (
      <div className="p-8 flex items-center justify-center">
        <LoadingSpinner size="lg" />
      </div>
    )
  }

  return (
    <div className="p-6">
      <div className="flex flex-col lg:flex-row gap-6">
        {/* Filters Sidebar */}
        <div className="lg:w-80 flex-shrink-0">
          <EventFilters
            user={user}
            bands={bands}
            filters={filters}
            onFiltersChange={setFilters}
            onCreateEvent={handleCreateEvent}
          />
        </div>

        {/* Calendar */}
        <div className="flex-1">
          <div className="bg-white rounded-lg shadow">
            <div className="p-4 border-b border-gray-200">
              <div className="flex items-center justify-between">
                <h2 className="text-lg font-medium text-gray-900">
                  Calendario Eventi
                </h2>
                <button
                  onClick={handleCreateEvent}
                  className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-primary-600 hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
                >
                  <Plus className="w-4 h-4 mr-2" />
                  Nuovo Evento
                </button>
              </div>
            </div>
            
            <div className="p-4">
              {loading && (
                <div className="absolute inset-0 bg-white bg-opacity-75 flex items-center justify-center z-10">
                  <LoadingSpinner size="lg" />
                </div>
              )}
              
              <FullCalendar
                plugins={[dayGridPlugin, timeGridPlugin, interactionPlugin]}
                headerToolbar={{
                  left: 'prev,next today',
                  center: 'title',
                  right: 'dayGridMonth,timeGridWeek,timeGridDay'
                }}
                initialView="dayGridMonth"
                editable={false}
                selectable={true}
                selectMirror={true}
                dayMaxEvents={true}
                weekends={true}
                events={calendarEvents}
                height="auto"
                locale="it"
                firstDay={1} // Monday
                allDaySlot={true}
                displayEventTime={true}
                eventTimeFormat={{
                  hour: '2-digit',
                  minute: '2-digit',
                  hour12: false
                }}
                dayHeaderFormat={{
                  weekday: 'short',
                  day: 'numeric'
                }}
                dateClick={handleDateClick}
                eventClick={handleEventClick}
                nowIndicator={true}
                scrollTime="09:00:00"
                expandRows={true}
                stickyHeaderDates={true}
              />
            </div>
          </div>
        </div>
      </div>

      {/* Event Modal */}
      {isEventModalOpen && (
        <EventModal
          user={user}
          event={selectedEvent}
          isCreating={isCreating}
          selectedDate={selectedDate}
          bands={bands}
          onSave={handleEventSaved}
          onClose={() => setIsEventModalOpen(false)}
        />
      )}
    </div>
  )
}