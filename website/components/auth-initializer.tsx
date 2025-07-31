'use client'
import { useEffect } from 'react'
import { authService } from '@/services/auth.service'

export function AuthInitializer({ children }: { children: React.ReactNode }) {
  useEffect(() => {
  
    authService.syncTokens()


    const checkTokenExpiry = () => {
      if (authService.isAuthenticated() && authService.isTokenExpired()) {
      
        authService.refreshToken().catch(() => {
       
          window.location.href = '/'
        })
      }
    }

    // Check token expiry every 5 minutes
    const interval = setInterval(checkTokenExpiry, 5 * 60 * 1000)

    // Cleanup
    return () => clearInterval(interval)
  }, [])

  return <>{children}</>
}
