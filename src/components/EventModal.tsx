'use client'

import { useState, useEffect } from 'react'
import { useForm } from 'react-hook-form'
import { AuthUser, Event, Band, CreateEventForm } from '@/types'
import { X, Save, Trash2, MapPin, Clock, Euro } from 'lucide-react'
import LoadingSpinner from './LoadingSpinner'

interface EventModalProps {
  user: AuthUser
  event: Event | null
  isCreating: boolean
  selectedDate: string | null
  bands: Band[]
  onSave: () => void
  onClose: () => void
}

export default function EventModal({
  user,
  event,
  isCreating,
  selectedDate,
  bands,
  onSave,
  onClose
}: EventModalProps) {
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState('')
  const [activeTab, setActiveTab] = useState('details')

  const { register, handleSubmit, formState: { errors }, reset, setValue, watch } = useForm<CreateEventForm>()

  const watchedType = watch('type')
  const watchedAllDay = watch('allDay')

  useEffect(() => {
    if (isCreating && selectedDate) {
      // Set default values for new event
      const date = new Date(selectedDate)
      const startTime = new Date(date)
      startTime.setHours(20, 0, 0, 0)
      const endTime = new Date(date)
      endTime.setHours(22, 0, 0, 0)

      reset({
        bandId: user.bands[0]?.id || '',
        type: 'CONCERTO',
        title: '',
        start: startTime.toISOString().slice(0, 16),
        end: endTime.toISOString().slice(0, 16),
        allDay: false,
        status: 'OPZIONE',
        privacy: 'BAND',
        notes: '',
        valuta: 'EUR'
      })
    } else if (event) {
      // Set values for editing existing event
      reset({
        bandId: event.bandId,
        type: event.type,
        title: event.title,
        start: new Date(event.start).toISOString().slice(0, 16),
        end: new Date(event.end).toISOString().slice(0, 16),
        allDay: event.allDay,
        status: event.status,
        privacy: event.privacy,
        notes: event.notes || '',
        cachet: event.cachet || undefined,
        acconto: event.acconto || undefined,
        spese: event.spese || undefined,
        valuta: event.valuta || 'EUR',
        venueName: event.venue?.venue?.name || '',
        venueAddress: event.venue?.venue?.address || '',
        venueCity: event.venue?.venue?.city || '',
        venueCountry: event.venue?.venue?.country || 'IT',
      })
    }
  }, [event, isCreating, selectedDate, user.bands, reset])

  const availableBands = user.isAdmin 
    ? bands 
    : bands.filter(band => user.bands.some(userBand => userBand.id === band.id))

  const onSubmit = async (data: CreateEventForm) => {
    setIsLoading(true)
    setError('')

    try {
      const token = localStorage.getItem('accessToken')
      const url = isCreating ? '/api/events' : `/api/events/${event?.id}`
      const method = isCreating ? 'POST' : 'PATCH'

      // Convert dates to proper ISO format
      const eventData = { ...data }
      if (data.allDay) {
        const startDate = new Date(data.start)
        const endDate = new Date(data.end)
        eventData.start = new Date(startDate.getFullYear(), startDate.getMonth(), startDate.getDate()).toISOString()
        eventData.end = new Date(endDate.getFullYear(), endDate.getMonth(), endDate.getDate(), 23, 59, 59).toISOString()
      } else {
        // Convert datetime-local format to ISO
        eventData.start = new Date(data.start).toISOString()
        eventData.end = new Date(data.end).toISOString()
      }

      const response = await fetch(url, {
        method,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify(eventData)
      })

      const result = await response.json()

      if (!response.ok) {
        if (response.status === 409 && result.conflicts) {
          setError(`Conflitto rilevato con: ${result.conflicts.map((c: any) => c.title).join(', ')}`)
        } else if (response.status === 400 && result.details) {
          console.error('Validation details:', result.details)
          const validationErrors = result.details.map((err: any) => `${err.path.join('.')}: ${err.message}`).join('\n')
          setError(`Errori di validazione:\n${validationErrors}`)
        } else {
          throw new Error(result.error || 'Errore durante il salvataggio')
        }
        return
      }

      console.log('Event saved successfully, calling onSave callback')
      onSave()
    } catch (error) {
      setError(error instanceof Error ? error.message : 'Errore sconosciuto')
    } finally {
      setIsLoading(false)
    }
  }

  const handleDelete = async () => {
    if (!event || !confirm('Sei sicuro di voler eliminare questo evento?')) {
      return
    }

    setIsLoading(true)
    setError('')

    try {
      const token = localStorage.getItem('accessToken')
      const response = await fetch(`/api/events/${event.id}`, {
        method: 'DELETE',
        headers: {
          'Authorization': `Bearer ${token}`
        }
      })

      if (!response.ok) {
        const result = await response.json()
        throw new Error(result.error || 'Errore durante l\'eliminazione')
      }

      onSave()
    } catch (error) {
      setError(error instanceof Error ? error.message : 'Errore sconosciuto')
    } finally {
      setIsLoading(false)
    }
  }

  const eventTypes = [
    { value: 'CONCERTO', label: 'Concerto' },
    { value: 'INDISPONIBILITA', label: 'Indisponibilità' },
    ...(user.isAdmin ? [{ value: 'BLOCCO_AGENZIA', label: 'Blocco Agenzia' }] : [])
  ]

  const eventStatuses = [
    { value: 'OPZIONE', label: 'Opzione' },
    { value: 'CONFERMATO', label: 'Confermato' },
    { value: 'ANNULLATO', label: 'Annullato' }
  ]

  const privacyOptions = [
    { value: 'BAND', label: 'Band' },
    ...(user.isAdmin ? [{ value: 'AGENZIA', label: 'Agenzia' }] : [])
  ]

  const tabs = [
    { id: 'details', label: 'Dettagli', icon: Clock },
    { id: 'venue', label: 'Venue', icon: MapPin },
    { id: 'financial', label: 'Finanze', icon: Euro },
  ]

  return (
    <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
      <div className="relative top-20 mx-auto p-5 border w-full max-w-2xl shadow-lg rounded-md bg-white">
        <div className="flex items-center justify-between mb-6">
          <h3 className="text-lg font-medium text-gray-900">
            {isCreating ? 'Nuovo Evento' : 'Modifica Evento'}
          </h3>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        {error && (
          <div className="mb-4 bg-red-50 border border-red-200 rounded-md p-4">
            <p className="text-sm text-red-800">{error}</p>
          </div>
        )}

        <form onSubmit={handleSubmit(onSubmit)}>
          {/* Tabs */}
          <div className="border-b border-gray-200 mb-6">
            <nav className="-mb-px flex space-x-8">
              {tabs.map((tab) => {
                const Icon = tab.icon
                return (
                  <button
                    key={tab.id}
                    type="button"
                    onClick={() => setActiveTab(tab.id)}
                    className={`${
                      activeTab === tab.id
                        ? 'border-primary-500 text-primary-600'
                        : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                    } whitespace-nowrap py-2 px-1 border-b-2 font-medium text-sm flex items-center`}
                  >
                    <Icon className="w-4 h-4 mr-2" />
                    {tab.label}
                  </button>
                )
              })}
            </nav>
          </div>

          {/* Details Tab */}
          {activeTab === 'details' && (
            <div className="space-y-4">
              {/* Band Selection */}
              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Band *
                </label>
                <select
                  {...register('bandId', { required: 'Band è richiesta' })}
                  className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500 sm:text-sm"
                >
                  <option value="">Seleziona una band</option>
                  {availableBands.map(band => (
                    <option key={band.id} value={band.id}>{band.name}</option>
                  ))}
                </select>
                {errors.bandId && (
                  <p className="mt-1 text-sm text-red-600">{errors.bandId.message}</p>
                )}
              </div>

              {/* Event Type */}
              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Tipo *
                </label>
                <select
                  {...register('type', { required: 'Tipo è richiesto' })}
                  className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500 sm:text-sm"
                >
                  {eventTypes.map(type => (
                    <option key={type.value} value={type.value}>{type.label}</option>
                  ))}
                </select>
              </div>

              {/* Title */}
              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Titolo *
                </label>
                <input
                  type="text"
                  {...register('title', { required: 'Titolo è richiesto' })}
                  className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500 sm:text-sm"
                  placeholder="Inserisci titolo evento"
                />
                {errors.title && (
                  <p className="mt-1 text-sm text-red-600">{errors.title.message}</p>
                )}
              </div>

              {/* All Day Toggle */}
              <div className="flex items-center">
                <input
                  type="checkbox"
                  {...register('allDay')}
                  className="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
                />
                <label className="ml-2 block text-sm text-gray-900">
                  Tutto il giorno
                </label>
              </div>

              {/* Date and Time */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700">
                    {watchedAllDay ? 'Data Inizio *' : 'Inizio *'}
                  </label>
                  <input
                    type={watchedAllDay ? 'date' : 'datetime-local'}
                    {...register('start', { required: 'Data/ora inizio è richiesta' })}
                    className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500 sm:text-sm"
                  />
                  {errors.start && (
                    <p className="mt-1 text-sm text-red-600">{errors.start.message}</p>
                  )}
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700">
                    {watchedAllDay ? 'Data Fine *' : 'Fine *'}
                  </label>
                  <input
                    type={watchedAllDay ? 'date' : 'datetime-local'}
                    {...register('end', { required: 'Data/ora fine è richiesta' })}
                    className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500 sm:text-sm"
                  />
                  {errors.end && (
                    <p className="mt-1 text-sm text-red-600">{errors.end.message}</p>
                  )}
                </div>
              </div>

              {/* Status */}
              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Stato *
                </label>
                <select
                  {...register('status', { required: 'Stato è richiesto' })}
                  className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500 sm:text-sm"
                >
                  <option value="">Seleziona uno stato</option>
                  {eventStatuses.map(status => (
                    <option key={status.value} value={status.value}>{status.label}</option>
                  ))}
                </select>
                {errors.status && (
                  <p className="mt-1 text-sm text-red-600">{errors.status.message}</p>
                )}
              </div>

              {/* Privacy */}
              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Privacy
                </label>
                <select
                  {...register('privacy')}
                  className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500 sm:text-sm"
                >
                  {privacyOptions.map(option => (
                    <option key={option.value} value={option.value}>{option.label}</option>
                  ))}
                </select>
              </div>

              {/* Notes */}
              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Note
                </label>
                <textarea
                  {...register('notes')}
                  rows={3}
                  className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500 sm:text-sm"
                  placeholder="Note aggiuntive..."
                />
              </div>
            </div>
          )}

          {/* Venue Tab */}
          {activeTab === 'venue' && watchedType === 'CONCERTO' && (
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Nome Venue
                </label>
                <input
                  type="text"
                  {...register('venueName')}
                  className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500 sm:text-sm"
                  placeholder="Nome del locale"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Indirizzo
                </label>
                <input
                  type="text"
                  {...register('venueAddress')}
                  className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500 sm:text-sm"
                  placeholder="Indirizzo completo"
                />
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700">
                    Città
                  </label>
                  <input
                    type="text"
                    {...register('venueCity')}
                    className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500 sm:text-sm"
                    placeholder="Città"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700">
                    Paese
                  </label>
                  <input
                    type="text"
                    {...register('venueCountry')}
                    className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500 sm:text-sm"
                    placeholder="IT"
                  />
                </div>
              </div>
            </div>
          )}

          {/* Financial Tab */}
          {activeTab === 'financial' && watchedType === 'CONCERTO' && (
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Valuta
                </label>
                <select
                  {...register('valuta')}
                  className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500 sm:text-sm"
                >
                  <option value="EUR">EUR</option>
                  <option value="USD">USD</option>
                  <option value="GBP">GBP</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Cachet
                </label>
                <input
                  type="number"
                  step="0.01"
                  {...register('cachet', { valueAsNumber: true })}
                  className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500 sm:text-sm"
                  placeholder="0.00"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Acconto
                </label>
                <input
                  type="number"
                  step="0.01"
                  {...register('acconto', { valueAsNumber: true })}
                  className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500 sm:text-sm"
                  placeholder="0.00"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Spese
                </label>
                <input
                  type="number"
                  step="0.01"
                  {...register('spese', { valueAsNumber: true })}
                  className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500 sm:text-sm"
                  placeholder="0.00"
                />
              </div>
            </div>
          )}

          {/* Action Buttons */}
          <div className="mt-6 flex justify-between">
            <div>
              {!isCreating && event && (event as any).canDelete && (
                <button
                  type="button"
                  onClick={handleDelete}
                  disabled={isLoading}
                  className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 disabled:opacity-50"
                >
                  {isLoading ? <LoadingSpinner size="sm" /> : <Trash2 className="w-4 h-4 mr-2" />}
                  Elimina
                </button>
              )}
            </div>
            <div className="flex space-x-3">
              <button
                type="button"
                onClick={onClose}
                disabled={isLoading}
                className="px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 disabled:opacity-50"
              >
                Annulla
              </button>
              <button
                type="submit"
                disabled={isLoading}
                className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-primary-600 hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 disabled:opacity-50"
              >
                {isLoading ? <LoadingSpinner size="sm" /> : <Save className="w-4 h-4 mr-2" />}
                {isCreating ? 'Crea Evento' : 'Salva Modifiche'}
              </button>
            </div>
          </div>
        </form>
      </div>
    </div>
  )
}