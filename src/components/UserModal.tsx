'use client'

import { useState, useEffect } from 'react'
import { useForm } from 'react-hook-form'
import { User, Band } from '@/types'
import { X, Save } from 'lucide-react'
import LoadingSpinner from './LoadingSpinner'

interface UserModalProps {
  user: User | null
  isCreating: boolean
  onSave: () => void
  onClose: () => void
}

interface UserFormData {
  name: string
  email: string
  password?: string
  isAdmin: boolean
  bandIds: string[]
}

export default function UserModal({
  user,
  isCreating,
  onSave,
  onClose
}: UserModalProps) {
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState('')
  const [bands, setBands] = useState<Band[]>([])

  const { register, handleSubmit, formState: { errors }, reset, watch } = useForm<UserFormData>()

  useEffect(() => {
    loadBands()
  }, [])

  useEffect(() => {
    if (isCreating) {
      reset({
        name: '',
        email: '',
        password: '',
        isAdmin: false,
        bandIds: []
      })
    } else if (user) {
      reset({
        name: user.name,
        email: user.email,
        password: '',
        isAdmin: user.isAdmin,
        bandIds: user.bands?.map(b => b.bandId) || []
      })
    }
  }, [user, isCreating, reset])

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

  const onSubmit = async (data: UserFormData) => {
    setIsLoading(true)
    setError('')

    try {
      const token = localStorage.getItem('accessToken')
      const url = isCreating ? '/api/users' : `/api/users/${user?.id}`
      const method = isCreating ? 'POST' : 'PATCH'

      // Don't send password if it's empty for updates
      const submitData = { ...data }
      if (!isCreating && !data.password) {
        delete submitData.password
      }

      const response = await fetch(url, {
        method,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify(submitData)
      })

      const result = await response.json()

      if (!response.ok) {
        if (response.status === 400 && result.details) {
          const validationErrors = result.details.map((err: any) => `${err.path.join('.')}: ${err.message}`).join('\n')
          setError(`Errori di validazione:\n${validationErrors}`)
        } else {
          throw new Error(result.error || 'Errore durante il salvataggio')
        }
        return
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
            {isCreating ? 'Nuovo Utente' : 'Modifica Utente'}
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
            <pre className="text-sm text-red-800 whitespace-pre-wrap">{error}</pre>
          </div>
        )}

        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
          {/* Name */}
          <div>
            <label className="block text-sm font-medium text-gray-700">
              Nome *
            </label>
            <input
              type="text"
              {...register('name', { required: 'Nome è richiesto' })}
              className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500 sm:text-sm"
              placeholder="Inserisci nome"
            />
            {errors.name && (
              <p className="mt-1 text-sm text-red-600">{errors.name.message}</p>
            )}
          </div>

          {/* Email */}
          <div>
            <label className="block text-sm font-medium text-gray-700">
              Email *
            </label>
            <input
              type="email"
              {...register('email', { 
                required: 'Email è richiesta',
                pattern: {
                  value: /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i,
                  message: 'Email non valida'
                }
              })}
              className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500 sm:text-sm"
              placeholder="email@esempio.com"
            />
            {errors.email && (
              <p className="mt-1 text-sm text-red-600">{errors.email.message}</p>
            )}
          </div>

          {/* Password */}
          <div>
            <label className="block text-sm font-medium text-gray-700">
              Password {isCreating && '*'}
              {!isCreating && <span className="text-gray-500">(lascia vuoto per non modificare)</span>}
            </label>
            <input
              type="password"
              {...register('password', { 
                required: isCreating ? 'Password è richiesta' : false,
                minLength: {
                  value: 6,
                  message: 'Password deve essere almeno 6 caratteri'
                }
              })}
              className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500 sm:text-sm"
              placeholder="Password"
            />
            {errors.password && (
              <p className="mt-1 text-sm text-red-600">{errors.password.message}</p>
            )}
          </div>

          {/* Admin Toggle */}
          <div className="flex items-center">
            <input
              type="checkbox"
              {...register('isAdmin')}
              className="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
            />
            <label className="ml-2 block text-sm text-gray-900">
              Amministratore
            </label>
          </div>

          {/* Band Assignment */}
          <div>
            <label className="block text-sm font-medium text-gray-700">
              Band Assegnate
            </label>
            <div className="mt-2 space-y-2 max-h-32 overflow-y-auto border border-gray-200 rounded-md p-2">
              {bands.map((band) => (
                <div key={band.id} className="flex items-center">
                  <input
                    type="checkbox"
                    value={band.id}
                    {...register('bandIds')}
                    className="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
                  />
                  <label className="ml-2 block text-sm text-gray-900">
                    {band.name}
                  </label>
                </div>
              ))}
            </div>
          </div>

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
              {isCreating ? 'Crea Utente' : 'Salva Modifiche'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}