'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import Calendar from '@/components/Calendar'
import LoadingSpinner from '@/components/LoadingSpinner'
import Header from '@/components/Header'
import { AuthUser } from '@/types'

export default function Dashboard() {
  const [user, setUser] = useState<AuthUser | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const router = useRouter()

  useEffect(() => {
    const token = localStorage.getItem('accessToken')
    if (!token) {
      router.push('/')
      return
    }

    // Get user data from localStorage first (for immediate UI)
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
      setIsLoading(false)
    })
    .catch(() => {
      localStorage.removeItem('accessToken')
      localStorage.removeItem('refreshToken')
      localStorage.removeItem('user')
      router.push('/')
    })
  }, [router])

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
          <div className="border-4 border-dashed border-gray-200 rounded-lg">
            <Calendar user={user} />
          </div>
        </div>
      </main>
    </div>
  )
}