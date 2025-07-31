
import { BaseService } from './config/api.config'

export interface ApiUser {
  id: string
  name: string
  email: string
  plan_type: string
  status: string
  last_login: string | null
  created_at: string
  updated_at: string
}

export interface UserListResponse {
  success: boolean
  message: string
  data: {
    users: ApiUser[]
    total: number
    page: number
    page_size: number
    total_pages: number
  }
  timestamp: string
}

interface UserListParams {
  page?: number
  limit?: number
  search?: string
  status?: string
  plan_type?: string
  sort_by?: string
  sort_order?: 'asc' | 'desc'
}

interface CreateUserData {
  name: string
  email: string
  password: string
  plan_type?: string
}

interface UpdateUserData {
  name?: string
  email?: string
  plan_type?: string
  status?: string
}

class UserService extends BaseService {
  constructor() {
    super('/v1/admin/users')
  }

  // Get all users with pagination and filters
  async getUsers(params?: UserListParams): Promise<UserListResponse> {
    const queryParams = new URLSearchParams()
    
    if (params) {
      Object.entries(params).forEach(([key, value]) => {
        if (value !== undefined && value !== null && value !== '') {
          queryParams.append(key, value.toString())
        }
      })
    }
    
    const queryString = queryParams.toString()
    const endpoint = queryString ? `?${queryString}` : ''
    
    return this.get<UserListResponse>(endpoint)
  }

  // Get user by ID
  async getUserById(userId: string): Promise<{ success: boolean; data: ApiUser }> {
    return this.get<{ success: boolean; data: ApiUser }>(`/${userId}`)
  }

  // Create new user
  async createUser(userData: CreateUserData): Promise<{ success: boolean; data: ApiUser }> {
    return this.post<{ success: boolean; data: ApiUser }, CreateUserData>(userData)
  }

  // Update user
  async updateUser(userId: string, userData: UpdateUserData): Promise<{ success: boolean; data: ApiUser }> {
    return this.put<{ success: boolean; data: ApiUser }, UpdateUserData>(userData, `/${userId}`)
  }

  // Delete user
  async deleteUser(userId: string): Promise<{ success: boolean; message: string }> {
    return this.delete<{ success: boolean; message: string }>(`/${userId}`)
  }

  // Suspend user
  async suspendUser(userId: string, reason?: string): Promise<{ success: boolean; data: ApiUser }> {
    return this.patch<{ success: boolean; data: ApiUser }, { reason?: string }>({ reason }, `/${userId}/suspend`)
  }

  // Activate user
  async activateUser(userId: string): Promise<{ success: boolean; data: ApiUser }> {
    return this.patch<{ success: boolean; data: ApiUser }, {}>({}, `/${userId}/activate`)
  }

  // Get user statistics
  async getUserStats(): Promise<{ success: boolean; data: any }> {
    return this.get<{ success: boolean; data: any }>('/stats')
  }
}

// Export singleton instance
export const userService = new UserService()
export default userService