import { cookieUtils } from '@/lib/cookies'
import { BaseService } from './config/api.config'
import type {
  LoginRequest,
  RegisterRequest,
  BackendLoginResponse,
  UserResponse,
  AuthResponse
} from '@/lib/types/api'

class AuthService extends BaseService {
  constructor() {
    super('/v1')
  }

  private storeAuthData(token: string, refreshToken: string, expiresIn: number, userData: UserResponse['data']) {
    if (typeof window === 'undefined') return

    const expiryTime = Date.now() + expiresIn * 1000

    localStorage.setItem('authToken', token)
    localStorage.setItem('refreshToken', refreshToken)
    localStorage.setItem('tokenExpiry', expiryTime.toString())
    localStorage.setItem('userData', JSON.stringify(userData))

    cookieUtils.syncTokensToCookies()
  }

  private clearAuthData() {
    if (typeof window === 'undefined') return

    localStorage.removeItem('authToken')
    localStorage.removeItem('refreshToken')
    localStorage.removeItem('tokenExpiry')
    localStorage.removeItem('userData')

    cookieUtils.clearAuthCookies()
  }

  async login(credentials: LoginRequest): Promise<AuthResponse> {
    try {
      const loginResponse = await this.post<BackendLoginResponse, LoginRequest>(
        credentials,
        '/auth/login'
      )

      if (!loginResponse.success) {
        throw new Error(loginResponse.message || 'Login failed')
      }

      const { access_token, refresh_token, expires_in } = loginResponse.data

      const userResponse = await this.get<UserResponse>('/me')

      if (!userResponse.success) {
        throw new Error(userResponse.message || 'Failed to fetch user data')
      }

      this.storeAuthData(access_token, refresh_token, expires_in, userResponse.data)

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

  async register(userData: RegisterRequest): Promise<AuthResponse> {
    try {
      const response = await this.post<BackendLoginResponse, RegisterRequest>(userData, '/auth/register')

      if (!response.success) {
        throw new Error(response.message || 'Registration failed')
      }

      const { access_token, refresh_token, expires_in } = response.data

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

  async getCurrentUser(): Promise<UserResponse['data']> {
    const response = await this.get<UserResponse>('/me')

    if (!response.success) {
      throw new Error(response.message || 'Failed to fetch user data')
    }

    if (typeof window !== 'undefined') {
      localStorage.setItem('userData', JSON.stringify(response.data))
      cookieUtils.syncTokensToCookies()
    }

    return response.data
  }

  getStoredUser(): UserResponse['data'] | null {
    if (typeof window === 'undefined') return null

    const userData = localStorage.getItem('userData')
    return userData ? JSON.parse(userData) : null
  }

  async logout(): Promise<void> {
    try {
      await this.post({}, '/auth/logout')
    } catch (error) {
      console.error('Logout API call failed:', error)
    } finally {
      this.clearAuthData()
    }
  }

  async refreshToken(): Promise<AuthResponse> {
    const refreshToken = typeof window !== 'undefined' ? localStorage.getItem('refreshToken') : null

    if (!refreshToken) {
      throw new Error('No refresh token available')
    }

    try {
      const response = await this.post<BackendLoginResponse, { refresh_token: string }>(
        { refresh_token: refreshToken },
        '/auth/refresh-token'
      )

      if (!response.success) {
        throw new Error(response.message || 'Token refresh failed')
      }

      const { access_token, refresh_token: newRefreshToken, expires_in } = response.data

      const userData = await this.getCurrentUser()

      this.storeAuthData(access_token, newRefreshToken, expires_in, userData)

      return {
        user: userData,
        token: access_token,
        refreshToken: newRefreshToken,
        expiresIn: expires_in
      }
    } catch (error) {
      this.clearAuthData()
      throw error
    }
  }

  isAuthenticated(): boolean {
    if (typeof window === 'undefined') return false

    const token = localStorage.getItem('authToken')
    const expiry = localStorage.getItem('tokenExpiry')

    if (!token || !expiry) return false

    if (Date.now() > parseInt(expiry)) {
      this.clearAuthData()
      return false
    }

    return true
  }

  getToken(): string | null {
    if (typeof window === 'undefined') return null
    return localStorage.getItem('authToken')
  }

  isTokenExpired(): boolean {
    if (typeof window === 'undefined') return true

    const expiry = localStorage.getItem('tokenExpiry')
    if (!expiry) return true

    return Date.now() > parseInt(expiry)
  }

  getUserRole(): string | null {
    const user = this.getStoredUser()
    return user?.role || null
  }

  hasRole(role: string): boolean {
    const userRole = this.getUserRole()
    return userRole === role
  }

  isAdmin(): boolean {
    return this.hasRole('admin')
  }

  getUserPlan(): { type: string; name: string; status: string } | null {
    const user = this.getStoredUser()
    if (!user) return null

    return {
      type: user.plan_type,
      name: user.plan_name,
      status: user.plan_status
    }
  }

  syncTokens(): void {
    cookieUtils.syncTokensToCookies()
  }
}

// Export singleton instance
export const authService = new AuthService()
export default authService