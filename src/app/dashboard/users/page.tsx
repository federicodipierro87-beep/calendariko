'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import Header from '@/components/Header'
import LoadingSpinner from '@/components/LoadingSpinner'
import UserModal from '@/components/UserModal'
import { AuthUser, User } from '@/types'
import { Users, UserPlus, Edit2, Trash2, Shield, ShieldCheck } from 'lucide-react'

export default function UsersPage() {
  const [user, setUser] = useState<AuthUser | null>(null)
  const [users, setUsers] = useState<User[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState('')
  const [selectedUser, setSelectedUser] = useState<User | null>(null)
  const [isUserModalOpen, setIsUserModalOpen] = useState(false)
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
      const parsedUser = JSON.parse(userData)
      setUser(parsedUser)
      
      // Check if user is admin
      if (!parsedUser.isAdmin) {
        router.push('/dashboard')
        return
      }
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
      if (!result.data.isAdmin) {
        router.push('/dashboard')
        return
      }
      setUser(result.data)
      localStorage.setItem('user', JSON.stringify(result.data))
      loadUsers()
    })
    .catch(() => {
      localStorage.removeItem('accessToken')
      localStorage.removeItem('refreshToken')
      localStorage.removeItem('user')
      router.push('/')
    })
  }, [router])

  const loadUsers = async () => {
    try {
      const token = localStorage.getItem('accessToken')
      const response = await fetch('/api/users', {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      })
      
      if (response.ok) {
        const result = await response.json()
        setUsers(result.data)
      } else {
        setError('Errore nel caricamento degli utenti')
      }
    } catch (error) {
      setError('Errore nel caricamento degli utenti')
      console.error('Error loading users:', error)
    } finally {
      setIsLoading(false)
    }
  }

  const handleCreateUser = () => {
    setSelectedUser(null)
    setIsCreating(true)
    setIsUserModalOpen(true)
  }

  const handleEditUser = (userToEdit: User) => {
    setSelectedUser(userToEdit)
    setIsCreating(false)
    setIsUserModalOpen(true)
  }

  const handleDeleteUser = async (userToDelete: User) => {
    if (userToDelete.id === user?.id) {
      setError('Non puoi eliminare il tuo stesso account')
      return
    }

    if (!confirm(`Sei sicuro di voler eliminare l'utente "${userToDelete.name}"?`)) {
      return
    }

    try {
      const token = localStorage.getItem('accessToken')
      const response = await fetch(`/api/users/${userToDelete.id}`, {
        method: 'DELETE',
        headers: {
          'Authorization': `Bearer ${token}`
        }
      })

      if (response.ok) {
        loadUsers()
        setError('')
      } else {
        const result = await response.json()
        setError(result.error || 'Errore durante l\'eliminazione')
      }
    } catch (error) {
      setError('Errore durante l\'eliminazione')
      console.error('Error deleting user:', error)
    }
  }

  const handleUserSaved = () => {
    loadUsers()
    setIsUserModalOpen(false)
    setSelectedUser(null)
    setError('')
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
                <h1 className="text-2xl font-bold text-gray-900">Utenti</h1>
                <p className="mt-1 text-sm text-gray-600">
                  Gestisci gli utenti del sistema
                </p>
              </div>
              <button
                onClick={handleCreateUser}
                className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-primary-600 hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
              >
                <UserPlus className="w-4 h-4 mr-2" />
                Nuovo Utente
              </button>
            </div>
          </div>

          {error && (
            <div className="mb-6 bg-red-50 border border-red-200 rounded-md p-4">
              <p className="text-sm text-red-800">{error}</p>
            </div>
          )}

          {users.length === 0 ? (
            <div className="text-center py-12">
              <Users className="mx-auto h-12 w-12 text-gray-400" />
              <h3 className="mt-2 text-sm font-medium text-gray-900">Nessun utente</h3>
              <p className="mt-1 text-sm text-gray-500">
                Non ci sono utenti nel sistema.
              </p>
            </div>
          ) : (
            <div className="bg-white shadow overflow-hidden sm:rounded-md">
              <ul className="divide-y divide-gray-200">
                {users.map((userItem) => (
                  <li key={userItem.id}>
                    <div className="px-4 py-4 flex items-center justify-between">
                      <div className="flex items-center">
                        <div className="flex-shrink-0">
                          {userItem.isAdmin ? (
                            <ShieldCheck className="h-8 w-8 text-primary-600" />
                          ) : (
                            <Shield className="h-8 w-8 text-gray-400" />
                          )}
                        </div>
                        <div className="ml-4">
                          <div className="flex items-center">
                            <div className="text-sm font-medium text-gray-900">
                              {userItem.name}
                            </div>
                            {userItem.isAdmin && (
                              <span className="ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-primary-100 text-primary-800">
                                Admin
                              </span>
                            )}
                          </div>
                          <div className="text-sm text-gray-500">
                            {userItem.email}
                          </div>
                          <div className="text-xs text-gray-400">
                            {userItem.bands?.length || 0} band assegnate
                          </div>
                        </div>
                      </div>
                      <div className="flex space-x-3">
                        <button 
                          onClick={() => handleEditUser(userItem)}
                          className="inline-flex items-center px-3 py-1 border border-gray-300 rounded-md text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
                        >
                          <Edit2 className="w-4 h-4 mr-1" />
                          Modifica
                        </button>
                        {userItem.id !== user.id && (
                          <button 
                            onClick={() => handleDeleteUser(userItem)}
                            className="inline-flex items-center px-3 py-1 border border-red-300 rounded-md text-sm font-medium text-red-700 bg-white hover:bg-red-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
                          >
                            <Trash2 className="w-4 h-4 mr-1" />
                            Elimina
                          </button>
                        )}
                      </div>
                    </div>
                  </li>
                ))}
              </ul>
            </div>
          )}
        </div>
      </main>

      {/* User Modal */}
      {isUserModalOpen && (
        <UserModal
          user={selectedUser}
          isCreating={isCreating}
          onSave={handleUserSaved}
          onClose={() => setIsUserModalOpen(false)}
        />
      )}
    </div>
  )
}