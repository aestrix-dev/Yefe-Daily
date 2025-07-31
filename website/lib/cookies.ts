
export const cookieUtils = {
    setCookie: (name: string, value: string, days: number = 7) => {
      if (typeof window === 'undefined') return
  
      const expires = new Date()
      expires.setTime(expires.getTime() + days * 24 * 60 * 60 * 1000)
      
      const cookieOptions = [
        `${name}=${value}`,
        `expires=${expires.toUTCString()}`,
        'path=/',
        'SameSite=Strict',
        // Add Secure flag in production
        ...(process.env.NODE_ENV === 'production' ? ['Secure'] : [])
      ]
      
      document.cookie = cookieOptions.join('; ')
    },
  
    // Get a cookie value
    getCookie: (name: string): string | null => {
      if (typeof window === 'undefined') return null
  
      const nameEQ = name + '='
      const ca = document.cookie.split(';')
      
      for (let i = 0; i < ca.length; i++) {
        let c = ca[i]
        while (c.charAt(0) === ' ') c = c.substring(1, c.length)
        if (c.indexOf(nameEQ) === 0) return c.substring(nameEQ.length, c.length)
      }
      return null
    },
  
    // Delete a cookie
    deleteCookie: (name: string) => {
      if (typeof window === 'undefined') return
      
      document.cookie = `${name}=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/; SameSite=Strict`
    },
  
    // Sync localStorage tokens to cookies
    syncTokensToCookies: () => {
      if (typeof window === 'undefined') return
  
      const authToken = localStorage.getItem('authToken')
      const refreshToken = localStorage.getItem('refreshToken')
      const tokenExpiry = localStorage.getItem('tokenExpiry')
      const userData = localStorage.getItem('userData')
  
      if (authToken) {
        cookieUtils.setCookie('authToken', authToken, 7)
      } else {
        cookieUtils.deleteCookie('authToken')
      }
  
      if (refreshToken) {
          cookieUtils.setCookie('refreshToken', refreshToken, 30)
      } else {
        cookieUtils.deleteCookie('refreshToken')
      }
  
      if (tokenExpiry) {
        cookieUtils.setCookie('tokenExpiry', tokenExpiry, 7)
      } else {
        cookieUtils.deleteCookie('tokenExpiry')
      }
  
      // Store user role for middleware role checking
      if (userData) {
        try {
          const user = JSON.parse(userData)
          if (user.role) {
            cookieUtils.setCookie('userRole', user.role, 7)
          }
        } catch (error) {
          console.error('Error parsing user data:', error)
        }
      } else {
        cookieUtils.deleteCookie('userRole')
      }
    },
  
    // Clear all auth-related cookies
    clearAuthCookies: () => {
      cookieUtils.deleteCookie('authToken')
      cookieUtils.deleteCookie('refreshToken')
      cookieUtils.deleteCookie('tokenExpiry')
      cookieUtils.deleteCookie('userRole')
    }
  }