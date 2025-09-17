
import { BaseService } from './config/api.config'
import type {
  ApiUser,
  UserListResponse,
  UserListParams,
  CreateUserRequest,
  UpdateUserRequest,
  UpdateUserStatusRequest,
  UpdateUserPlanRequest,
  BaseApiResponse
} from '@/lib/types/api'

class UserService extends BaseService {
  constructor() {
    super('/v1/admin')
  }

  // Get all users with pagination and filters (GET /admin/users)
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
    const endpoint = `/users${queryString ? `?${queryString}` : ''}`

    return this.get<UserListResponse>(endpoint)
  }

  // Get user by ID (GET /admin/{userID})
  async getUserById(userId: string): Promise<ApiUser> {
    return this.get<ApiUser>(`/${userId}`)
  }

  // Create new user (not in admin.md but keeping for completeness)
  async createUser(userData: CreateUserRequest): Promise<{ success: boolean; data: ApiUser }> {
    return this.post<{ success: boolean; data: ApiUser }, CreateUserRequest>(userData, '/users')
  }

  // Update user (not explicitly in admin.md but keeping for completeness)
  async updateUser(userId: string, userData: UpdateUserRequest): Promise<{ success: boolean; data: ApiUser }> {
    return this.put<{ success: boolean; data: ApiUser }, UpdateUserRequest>(userData, `/${userId}`)
  }

  // Update user status (PUT /admin/{userID}/status)
  async updateUserStatus(userId: string, statusData: UpdateUserStatusRequest): Promise<void> {
    return this.put<void, UpdateUserStatusRequest>(statusData, `/${userId}/status`)
  }

  // Update user plan (PUT /admin/{userID}/plan)
  async updateUserPlan(userId: string, planData: UpdateUserPlanRequest): Promise<void> {
    return this.put<void, UpdateUserPlanRequest>(planData, `/${userId}/plan`)
  }

  // Delete user (DELETE /admin/{userID})
  async deleteUser(userId: string): Promise<void> {
    return this.delete<void>(`/${userId}`)
  }

  // Legacy methods for backwards compatibility
  // Suspend user (deprecated - use updateUserStatus instead)
  async suspendUser(userId: string, reason?: string): Promise<void> {
    return this.updateUserStatus(userId, { status: 'suspend' })
  }

  // Activate user (deprecated - use updateUserStatus instead)
  async activateUser(userId: string): Promise<void> {
    return this.updateUserStatus(userId, { status: 'active' })
  }

  // Get user statistics (not in admin.md but keeping for existing functionality)
  async getUserStats(): Promise<{ success: boolean; data: any }> {
    return this.get<{ success: boolean; data: any }>('/users/stats')
  }
}

// Export singleton instance
export const userService = new UserService()
export default userService