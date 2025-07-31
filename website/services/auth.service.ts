// services/auth.service.ts

import { cookieUtils } from '@/lib/cookies'
import { BaseService } from './config/api.config'

interface LoginCredentials {
  email: string
  password: string
}

interface RegisterData {
  name: string
  email: string
  password: string
  confirmPassword: string
}

// Backend login response structure
interface LoginResponse {
  success: boolean
  message: string
  data: {
    access_token: string
    refresh_token: string
    expires_in: number
  }
  timestamp: string
}

interface UserResponse {
  success: boolean
  message: string
  data: {
    id: string
    email: string
    Name: string
    is_email_verified: boolean
    is_active: boolean
    created_at: string
    updated_at: string
    last_login_at: string
    user_profile: {
      id: string
      user_id: string
      date_of_birth: string | null
      phone_number: string
      avatar_url: string
      bio: string
      location: string
      notification_preferences: {
        notification_morning_prompt: boolean
        notification_evening_reflection: boolean
        notification_challange: boolean
        notification_language: string
        notification_reminders: {
          notification_reminders_morning_reminder: string
          notification_reminders_evening_reminder: string
        }
      }
      created_at: string
      updated_at: string
    }
    role: string
    plan_type: string
    plan_name: string
    plan_start_date: string
    plan_end_date: string | null
    plan_auto_renew: boolean
    plan_status: string
  }
  timestamp: string
}

// Standardized auth response for the frontend
interface AuthResponse {
  user: UserResponse['data']
  token: string
  refreshToken: string
  expiresIn: number
}

interface PasswordResetRequest {
  email: string
}

interface PasswordReset {
  token: string
  password: string
  confirmPassword: string
}

interface ChangePassword {
  currentPassword: string
  newPassword: string
  confirmPassword: string
}

class AuthService extends BaseService {
  constructor() {
    super('/v1')
  }

  // Store authentication data in both localStorage and cookies
  private storeAuthData(token: string, refreshToken: string, expiresIn: number, userData: UserResponse['data']) {
    if (typeof window === 'undefined') return

    const expiryTime = Date.now() + expiresIn * 1000

    // Store in localStorage
    localStorage.setItem('authToken', token)
    localStorage.setItem('refreshToken', refreshToken)
    localStorage.setItem('tokenExpiry', expiryTime.toString())
    localStorage.setItem('userData', JSON.stringify(userData))

    // Sync to cookies for middleware
    cookieUtils.syncTokensToCookies()
  }

  // Clear authentication data from both localStorage and cookies
  private clearAuthData() {
    if (typeof window === 'undefined') return

    // Clear localStorage
    localStorage.removeItem('authToken')
    localStorage.removeItem('refreshToken')
    localStorage.removeItem('tokenExpiry')
    localStorage.removeItem('userData')

    // Clear cookies
    cookieUtils.clearAuthCookies()
  }

  // Login user with automatic user data fetch
  async login(credentials: LoginCredentials): Promise<AuthResponse> {
    try {
      // Step 1: Login and get tokens
      const loginResponse = await this.post<LoginResponse, LoginCredentials>(
        credentials, 
        '/auth/login'
      )

      if (!loginResponse.success) {
        throw new Error(loginResponse.message || 'Login failed')
      }

      const { access_token, refresh_token, expires_in } = loginResponse.data

      // Store tokens temporarily for the user data request
      if (typeof window !== 'undefined') {
        localStorage.setItem('authToken', access_token)
      }

      // Step 2: Automatically fetch user data
      const userResponse = await this.get<UserResponse>('/me')

      if (!userResponse.success) {
        throw new Error(userResponse.message || 'Failed to fetch user data')
      }

      // Step 3: Store all authentication data
      this.storeAuthData(access_token, refresh_token, expires_in, userResponse.data)

      // Return standardized response
      return {
        user: userResponse.data,
        token: access_token,
        refreshToken: refresh_token,
        expiresIn: expires_in
      }

    } catch (error) {
      // Clean up on failure
      this.clearAuthData()
      throw error
    }
  }

  // Register new user
  async register(userData: RegisterData): Promise<AuthResponse> {
    try {
      const response = await this.post<LoginResponse, RegisterData>(userData, '/auth/register')
      
      if (!response.success) {
        throw new Error(response.message || 'Registration failed')
      }

      const { access_token, refresh_token, expires_in } = response.data

      // Store token temporarily
      if (typeof window !== 'undefined') {
        localStorage.setItem('authToken', access_token)
      }

      // Fetch user data after registration
      const userResponse = await this.get<UserResponse>('/me')

      if (userResponse.success) {
        this.storeAuthData(access_token, refresh_token, expires_in, userResponse.data)
      }

      return {
        user: userResponse.data,
        token: access_token,
        refreshToken: refresh_token,
        expiresIn: expires_in
      }
    } catch (error) {
      this.clearAuthData()
      throw error
    }
  }

  // Get current user data (from /v1/me endpoint)
  async getCurrentUser(): Promise<UserResponse['data']> {
    const response = await this.get<UserResponse>('/me')
    
    if (!response.success) {
      throw new Error(response.message || 'Failed to fetch user data')
    }

    // Update stored user data
    if (typeof window !== 'undefined') {
      localStorage.setItem('userData', JSON.stringify(response.data))
      cookieUtils.syncTokensToCookies() // Sync any role changes
    }

    return response.data
  }

  // Get user data from localStorage
  getStoredUser(): UserResponse['data'] | null {
    if (typeof window === 'undefined') return null
    
    const userData = localStorage.getItem('userData')
    return userData ? JSON.parse(userData) : null
  }

  // Logout user
  async logout(): Promise<void> {
    try {
      await this.post({}, '/auth/logout')
    } catch (error) {
      console.error('Logout API call failed:', error)
    } finally {
      this.clearAuthData()
    }
  }

  // Refresh token
  async refreshToken(): Promise<AuthResponse> {
    const refreshToken = typeof window !== 'undefined' ? localStorage.getItem('refreshToken') : null
    
    if (!refreshToken) {
      throw new Error('No refresh token available')
    }

    try {
      const response = await this.post<LoginResponse, { refresh_token: string }>(
        { refresh_token: refreshToken }, 
        '/auth/refresh-token'
      )

      if (!response.success) {
        throw new Error(response.message || 'Token refresh failed')
      }

      const { access_token, refresh_token: newRefreshToken, expires_in } = response.data

      // Get updated user data
      const userData = await this.getCurrentUser()

      // Store updated authentication data
      this.storeAuthData(access_token, newRefreshToken, expires_in, userData)

      return {
        user: userData,
        token: access_token,
        refreshToken: newRefreshToken,
        expiresIn: expires_in
      }
    } catch (error) {
      // If refresh fails, clear all auth data
      this.clearAuthData()
      throw error
    }
  }

  // Check if user is authenticated
  isAuthenticated(): boolean {
    if (typeof window === 'undefined') return false
    
    const token = localStorage.getItem('authToken')
    const expiry = localStorage.getItem('tokenExpiry')
    
    if (!token || !expiry) return false
    
    // Check if token is expired
    if (Date.now() > parseInt(expiry)) {
      this.clearAuthData()
      return false
    }
    
    return true
  }

  // Get stored token
  getToken(): string | null {
    if (typeof window === 'undefined') return null
    return localStorage.getItem('authToken')
  }

  // Check if token is expired
  isTokenExpired(): boolean {
    if (typeof window === 'undefined') return true
    
    const expiry = localStorage.getItem('tokenExpiry')
    if (!expiry) return true
    
    return Date.now() > parseInt(expiry)
  }

  // Get user role for authorization
  getUserRole(): string | null {
    const user = this.getStoredUser()
    return user?.role || null
  }

  // Check if user has a specific role
  hasRole(role: string): boolean {
    const userRole = this.getUserRole()
    return userRole === role
  }

  // Check if user is admin
  isAdmin(): boolean {
    return this.hasRole('admin')
  }

  // Get user plan information
  getUserPlan(): { type: string; name: string; status: string } | null {
    const user = this.getStoredUser()
    if (!user) return null
    
    return {
      type: user.plan_type,
      name: user.plan_name,
      status: user.plan_status
    }
  }

  // Sync tokens to cookies (call this on app initialization)
  syncTokens(): void {
    cookieUtils.syncTokensToCookies()
  }
}

// Export singleton instance
export const authService = new AuthService()
export default authService