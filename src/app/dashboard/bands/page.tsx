'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import Header from '@/components/Header'
import LoadingSpinner from '@/components/LoadingSpinner'
import BandModal from '@/components/BandModal'
import { AuthUser, Band } from '@/types'
import { Music, Users, Plus, Edit2, Trash2, Crown } from 'lucide-react'

export default function BandsPage() {
  const [user, setUser] = useState<AuthUser | null>(null)
  const [bands, setBands] = useState<Band[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState('')
  const [selectedBand, setSelectedBand] = useState<Band | null>(null)
  const [isBandModalOpen, setIsBandModalOpen] = useState(false)
  const [isCreating, setIsCreating] = useState(false)
  const router = useRouter()

  useEffect(() => {
    const token = localStorage.getItem('accessToken')
    if (!token) {
      router.push('/')
      return
    }

    // Get user data from localStorage first
    const userData = localStorage.getItem('user')
    if (userData) {
      setUser(JSON.parse(userData))
    }

    // Verify token and get fresh user data
    fetch('/api/auth/me', {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    })
    .then(response => {
      if (!response.ok) {
        throw new Error('Token invalid')
      }
      return response.json()
    })
    .then(result => {
      setUser(result.data)
      localStorage.setItem('user', JSON.stringify(result.data))
      loadBands()
    })
    .catch(() => {
      localStorage.removeItem('accessToken')
      localStorage.removeItem('refreshToken')
      localStorage.removeItem('user')
      router.push('/')
    })
  }, [router])

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
      } else {
        setError('Errore nel caricamento delle band')
      }
    } catch (error) {
      setError('Errore nel caricamento delle band')
      console.error('Error loading bands:', error)
    } finally {
      setIsLoading(false)
    }
  }

  const handleCreateBand = () => {
    setSelectedBand(null)
    setIsCreating(true)
    setIsBandModalOpen(true)
  }

  const handleEditBand = (band: Band) => {
    setSelectedBand(band)
    setIsCreating(false)
    setIsBandModalOpen(true)
  }

  const handleDeleteBand = async (band: Band) => {
    if (!confirm(`Sei sicuro di voler eliminare la band "${band.name}"?`)) {
      return
    }

    try {
      const token = localStorage.getItem('accessToken')
      const response = await fetch(`/api/bands/${band.id}`, {
        method: 'DELETE',
        headers: {
          'Authorization': `Bearer ${token}`
        }
      })

      if (response.ok) {
        loadBands()
      } else {
        const result = await response.json()
        setError(result.error || 'Errore durante l\'eliminazione')
      }
    } catch (error) {
      setError('Errore durante l\'eliminazione')
      console.error('Error deleting band:', error)
    }
  }

  const handleBandSaved = () => {
    loadBands()
    setIsBandModalOpen(false)
    setSelectedBand(null)
  }

  if (isLoading || !user) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <LoadingSpinner size="lg" />
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <Header user={user} />
      <main className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <div className="px-4 py-6 sm:px-0">
          <div className="mb-6">
            <div className="flex items-center justify-between">
              <div>
                <h1 className="text-2xl font-bold text-gray-900">Band</h1>
                <p className="mt-1 text-sm text-gray-600">
                  Gestisci le band e i membri
                </p>
              </div>
              {user.isAdmin && (
                <button
                  onClick={handleCreateBand}
                  className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-primary-600 hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
                >
                  <Plus className="w-4 h-4 mr-2" />
                  Nuova Band
                </button>
              )}
            </div>
          </div>

          {error && (
            <div className="mb-6 bg-red-50 border border-red-200 rounded-md p-4">
              <p className="text-sm text-red-800">{error}</p>
            </div>
          )}

          {bands.length === 0 ? (
            <div className="text-center py-12">
              <Music className="mx-auto h-12 w-12 text-gray-400" />
              <h3 className="mt-2 text-sm font-medium text-gray-900">Nessuna band</h3>
              <p className="mt-1 text-sm text-gray-500">
                Non ci sono band disponibili.
              </p>
            </div>
          ) : (
            <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
              {bands.map((band) => (
                <div key={band.id} className="bg-white overflow-hidden shadow rounded-lg">
                  <div className="p-6">
                    <div className="flex items-center">
                      <div className="flex-shrink-0">
                        <Music className="h-8 w-8 text-primary-600" />
                      </div>
                      <div className="ml-4 flex-1">
                        <h3 className="text-lg font-medium text-gray-900">
                          {band.name}
                        </h3>
                        {band.notes && (
                          <p className="text-sm text-gray-500 mt-1">
                            {band.notes}
                          </p>
                        )}
                      </div>
                    </div>
                    
                    <div className="mt-4 space-y-2">
                      <div className="flex items-center text-sm text-gray-500">
                        <Users className="h-4 w-4 mr-2" />
                        {band._count?.users || 0} membri
                      </div>
                      {(() => {
                        const referente = band.users?.find((userBand: any) => userBand.role === 'MANAGER')
                        return referente ? (
                          <div className="flex items-center text-sm text-primary-600">
                            <Crown className="h-4 w-4 mr-2" />
                            Referente: {referente.user?.name || 'Nome non disponibile'}
                          </div>
                        ) : (
                          <div className="flex items-center text-sm text-gray-400">
                            <Crown className="h-4 w-4 mr-2" />
                            Nessun referente
                          </div>
                        )
                      })()}
                    </div>

                    {user.isAdmin && (
                      <div className="mt-4 flex space-x-3">
                        <button 
                          onClick={() => handleEditBand(band)}
                          className="inline-flex items-center px-3 py-1 border border-gray-300 rounded-md text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
                        >
                          <Edit2 className="w-4 h-4 mr-1" />
                          Modifica
                        </button>
                        <button 
                          onClick={() => handleDeleteBand(band)}
                          className="inline-flex items-center px-3 py-1 border border-red-300 rounded-md text-sm font-medium text-red-700 bg-white hover:bg-red-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
                        >
                          <Trash2 className="w-4 h-4 mr-1" />
                          Elimina
                        </button>
                      </div>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </main>

      {/* Band Modal */}
      {isBandModalOpen && (
        <BandModal
          band={selectedBand}
          isCreating={isCreating}
          onSave={handleBandSaved}
          onClose={() => setIsBandModalOpen(false)}
        />
      )}
    </div>
  )
}