'use client'

import { useState } from 'react'
import { AuthUser, Band } from '@/types'
import { Search, Filter, Plus } from 'lucide-react'

interface EventFiltersProps {
  user: AuthUser
  bands: Band[]
  filters: {
    bandIds: string[]
    type: string[]
    status: string[]
    search: string
  }
  onFiltersChange: (filters: any) => void
  onCreateEvent: () => void
}

export default function EventFilters({ 
  user, 
  bands, 
  filters, 
  onFiltersChange, 
  onCreateEvent 
}: EventFiltersProps) {
  const [isExpanded, setIsExpanded] = useState(false)

  const eventTypes = [
    { value: 'CONCERTO', label: 'Concerti' },
    { value: 'INDISPONIBILITA', label: 'Indisponibilità' },
    ...(user.isAdmin ? [{ value: 'BLOCCO_AGENZIA', label: 'Blocco Agenzia' }] : [])
  ]

  const eventStatuses = [
    { value: 'TENTATIVO', label: 'Tentativo' },
    { value: 'OPZIONE', label: 'Opzione' },
    { value: 'CONFERMATO', label: 'Confermato' },
    { value: 'ANNULLATO', label: 'Annullato' }
  ]

  const handleBandToggle = (bandId: string) => {
    const newBandIds = filters.bandIds.includes(bandId)
      ? filters.bandIds.filter(id => id !== bandId)
      : [...filters.bandIds, bandId]
    
    onFiltersChange({ ...filters, bandIds: newBandIds })
  }

  const handleTypeToggle = (type: string) => {
    const newTypes = filters.type.includes(type)
      ? filters.type.filter(t => t !== type)
      : [...filters.type, type]
    
    onFiltersChange({ ...filters, type: newTypes })
  }

  const handleStatusToggle = (status: string) => {
    const newStatuses = filters.status.includes(status)
      ? filters.status.filter(s => s !== status)
      : [...filters.status, status]
    
    onFiltersChange({ ...filters, status: newStatuses })
  }

  const handleSearchChange = (search: string) => {
    onFiltersChange({ ...filters, search })
  }

  const clearFilters = () => {
    onFiltersChange({
      bandIds: user.isAdmin ? [] : user.bands.map(b => b.id),
      type: [],
      status: [],
      search: ''
    })
  }

  const availableBands = user.isAdmin ? bands : bands.filter(band => 
    user.bands.some(userBand => userBand.id === band.id)
  )

  return (
    <div className="bg-white rounded-lg shadow">
      <div className="p-4 border-b border-gray-200">
        <div className="flex items-center justify-between">
          <h3 className="text-lg font-medium text-gray-900">Filtri</h3>
          <button
            onClick={() => setIsExpanded(!isExpanded)}
            className="lg:hidden p-1 rounded-md text-gray-400 hover:text-gray-500"
          >
            <Filter className="w-5 h-5" />
          </button>
        </div>
      </div>

      <div className={`${isExpanded ? 'block' : 'hidden'} lg:block`}>
        <div className="p-4 space-y-6">
          {/* Create Button */}
          <button
            onClick={onCreateEvent}
            className="w-full flex items-center justify-center px-4 py-3 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-primary-600 hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
          >
            <Plus className="w-4 h-4 mr-2" />
            Nuovo Evento
          </button>

          {/* Search */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Cerca
            </label>
            <div className="relative">
              <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                <Search className="h-4 w-4 text-gray-400" />
              </div>
              <input
                type="text"
                value={filters.search}
                onChange={(e) => handleSearchChange(e.target.value)}
                className="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-md leading-5 bg-white placeholder-gray-500 focus:outline-none focus:placeholder-gray-400 focus:ring-1 focus:ring-primary-500 focus:border-primary-500 sm:text-sm"
                placeholder="Cerca eventi..."
              />
            </div>
          </div>

          {/* Bands */}
          {availableBands.length > 0 && (
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Band
              </label>
              <div className="space-y-2">
                {availableBands.map(band => (
                  <label key={band.id} className="flex items-center">
                    <input
                      type="checkbox"
                      checked={filters.bandIds.includes(band.id)}
                      onChange={() => handleBandToggle(band.id)}
                      className="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
                    />
                    <span className="ml-2 text-sm text-gray-700">{band.name}</span>
                  </label>
                ))}
              </div>
            </div>
          )}

          {/* Event Types */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Tipo Evento
            </label>
            <div className="space-y-2">
              {eventTypes.map(type => (
                <label key={type.value} className="flex items-center">
                  <input
                    type="checkbox"
                    checked={filters.type.includes(type.value)}
                    onChange={() => handleTypeToggle(type.value)}
                    className="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
                  />
                  <span className="ml-2 text-sm text-gray-700">{type.label}</span>
                </label>
              ))}
            </div>
          </div>

          {/* Event Status */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Stato
            </label>
            <div className="space-y-2">
              {eventStatuses.map(status => (
                <label key={status.value} className="flex items-center">
                  <input
                    type="checkbox"
                    checked={filters.status.includes(status.value)}
                    onChange={() => handleStatusToggle(status.value)}
                    className="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
                  />
                  <span className="ml-2 text-sm text-gray-700">{status.label}</span>
                </label>
              ))}
            </div>
          </div>

          {/* Clear Filters */}
          <button
            onClick={clearFilters}
            className="w-full text-sm text-gray-500 hover:text-gray-700 underline"
          >
            Cancella tutti i filtri
          </button>
        </div>
      </div>
    </div>
  )
}