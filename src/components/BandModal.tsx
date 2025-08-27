'use client'

import { useState, useEffect } from 'react'
import { useForm } from 'react-hook-form'
import { Band, User } from '@/types'
import { X, Save, UserCheck } from 'lucide-react'
import LoadingSpinner from './LoadingSpinner'

interface BandModalProps {
  band: Band | null
  isCreating: boolean
  onSave: () => void
  onClose: () => void
}

interface BandFormData {
  name: string
  description?: string
}

export default function BandModal({
  band,
  isCreating,
  onSave,
  onClose
}: BandModalProps) {
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState('')
  const [bandMembers, setBandMembers] = useState<User[]>([])
  const [selectedReferente, setSelectedReferente] = useState<string>('')

  const { register, handleSubmit, formState: { errors }, reset } = useForm<BandFormData>()

  useEffect(() => {
    if (isCreating) {
      reset({
        name: '',
        description: ''
      })
      setBandMembers([])
      setSelectedReferente('')
    } else if (band) {
      reset({
        name: band.name,
        description: band.description || ''
      })
      
      // Load band members
      const members = band.users?.map(ub => ({
        ...ub.user,
        role: ub.role
      })) || []
      setBandMembers(members as any)
      
      // Find current referente (MANAGER role)
      const referente = band.users?.find(ub => ub.role === 'MANAGER')
      setSelectedReferente(referente?.user.id || '')
    }
  }, [band, isCreating, reset])

  const updateReferente = async (bandId: string) => {
    try {
      const token = localStorage.getItem('accessToken')
      const response = await fetch(`/api/bands/${bandId}/referente`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({
          userId: selectedReferente || null
        })
      })

      if (!response.ok) {
        const result = await response.json()
        throw new Error(result.error || 'Errore durante l\'aggiornamento del referente')
      }
    } catch (error) {
      console.error('Error updating referente:', error)
      // Don't throw - we don't want to block the main save operation
    }
  }

  const onSubmit = async (data: BandFormData) => {
    setIsLoading(true)
    setError('')

    try {
      const token = localStorage.getItem('accessToken')
      const url = isCreating ? '/api/bands' : `/api/bands/${band?.id}`
      const method = isCreating ? 'POST' : 'PATCH'

      const response = await fetch(url, {
        method,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify(data)
      })

      const result = await response.json()

      if (!response.ok) {
        throw new Error(result.error || 'Errore durante il salvataggio')
      }

      // If not creating and referente changed, update it
      if (!isCreating && band && selectedReferente !== (band.users?.find(ub => ub.role === 'MANAGER')?.user.id || '')) {
        await updateReferente(result.data.id)
      }

      onSave()
    } catch (error) {
      setError(error instanceof Error ? error.message : 'Errore sconosciuto')
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
      <div className="relative top-20 mx-auto p-5 border w-full max-w-md shadow-lg rounded-md bg-white">
        <div className="flex items-center justify-between mb-6">
          <h3 className="text-lg font-medium text-gray-900">
            {isCreating ? 'Nuova Band' : 'Modifica Band'}
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

        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
          {/* Band Name */}
          <div>
            <label className="block text-sm font-medium text-gray-700">
              Nome Band *
            </label>
            <input
              type="text"
              {...register('name', { required: 'Nome band è richiesto' })}
              className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500 sm:text-sm"
              placeholder="Inserisci nome band"
            />
            {errors.name && (
              <p className="mt-1 text-sm text-red-600">{errors.name.message}</p>
            )}
          </div>

          {/* Description */}
          <div>
            <label className="block text-sm font-medium text-gray-700">
              Descrizione
            </label>
            <textarea
              {...register('description')}
              rows={3}
              className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500 sm:text-sm"
              placeholder="Descrizione della band..."
            />
          </div>

          {/* Referente Selection - only for existing bands with members */}
          {!isCreating && bandMembers.length > 0 && (
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                <UserCheck className="w-4 h-4 inline mr-2" />
                Referente Band
              </label>
              <div className="space-y-2">
                <div className="flex items-center">
                  <input
                    type="radio"
                    id="no-referente"
                    name="referente"
                    value=""
                    checked={selectedReferente === ''}
                    onChange={(e) => setSelectedReferente(e.target.value)}
                    className="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300"
                  />
                  <label htmlFor="no-referente" className="ml-2 block text-sm text-gray-900">
                    Nessun referente
                  </label>
                </div>
                {bandMembers.map((member) => (
                  <div key={member.id} className="flex items-center">
                    <input
                      type="radio"
                      id={`referente-${member.id}`}
                      name="referente"
                      value={member.id}
                      checked={selectedReferente === member.id}
                      onChange={(e) => setSelectedReferente(e.target.value)}
                      className="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300"
                    />
                    <label htmlFor={`referente-${member.id}`} className="ml-2 block text-sm text-gray-900">
                      {member.name} {(member as any).role === 'MANAGER' && '(Attuale)'}
                    </label>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Action Buttons */}
          <div className="flex justify-end space-x-3 mt-6">
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
              {isCreating ? 'Crea Band' : 'Salva Modifiche'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}