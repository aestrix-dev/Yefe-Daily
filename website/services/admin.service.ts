import { BaseService } from './config/api.config'
import type { Admin } from '@/lib/types'

interface AdminListParams {
  page?: number
  limit?: number
  search?: string
  status?: 'Active' | 'Suspended'
  role?: 'Admin' | 'Super Admin'
  sortBy?: string
  sortOrder?: 'asc' | 'desc'
}

interface AdminListResponse {
  admins: Admin[]
  total: number
  page: number
  limit: number
  totalPages: number
}

interface CreateAdminData {
  name: string
  email: string
  role: 'Admin' | 'Super Admin'
  permissions?: string[]
}

interface UpdateAdminData {
  name?: string
  email?: string
  role?: 'Admin' | 'Super Admin'
  status?: 'Active' | 'Suspended'
  permissions?: string[]
}

interface InviteAdminData {
  name: string
  email: string
  role: 'Admin' | 'Super Admin'
  permissions?: string[]
}

interface AdminStats {
  totalAdmins: number
  activeAdmins: number
  suspendedAdmins: number
  superAdmins: number
  regularAdmins: number
}

interface Permission {
  id: string
  name: string
  description: string
  category: string
}

class AdminService extends BaseService {
  constructor() {
    super('/admins')
  }

  // Get all admins with pagination and filters
  async getAdmins(params?: AdminListParams): Promise<AdminListResponse> {
    const queryParams = new URLSearchParams()
    
    if (params) {
      Object.entries(params).forEach(([key, value]) => {
        if (value !== undefined) {
          queryParams.append(key, value.toString())
        }
      })
    }
    
    const queryString = queryParams.toString()
    const endpoint = queryString ? `?${queryString}` : ''
    
    return this.get<AdminListResponse>(endpoint)
  }

  // Get admin by ID
  async getAdminById(adminId: string): Promise<Admin> {
    return this.get<Admin>(`/${adminId}`)
  }

  // Create new admin
  async createAdmin(adminData: CreateAdminData): Promise<Admin> {
    return this.post<Admin, CreateAdminData>(adminData)
  }

  // Invite new admin (sends invitation email)
  async inviteAdmin(inviteData: InviteAdminData): Promise<{ message: string; invitationId: string }> {
    return this.post<{ message: string; invitationId: string }, InviteAdminData>(inviteData, '/invite')
  }

  // Update admin
  async updateAdmin(adminId: string, adminData: UpdateAdminData): Promise<Admin> {
    return this.put<Admin, UpdateAdminData>(adminData, `/${adminId}`)
  }

  // Delete admin
  async deleteAdmin(adminId: string): Promise<{ message: string }> {
    return this.delete<{ message: string }>(`/${adminId}`)
  }

  // Suspend admin
  async suspendAdmin(adminId: string, reason?: string): Promise<Admin> {
    return this.patch<Admin, { reason?: string }>({ reason }, `/${adminId}/suspend`)
  }

  // Activate admin
  async activateAdmin(adminId: string): Promise<Admin> {
    return this.patch<Admin, {}>({}, `/${adminId}/activate`)
  }

  // Update admin role
  async updateAdminRole(adminId: string, role: 'Admin' | 'Super Admin'): Promise<Admin> {
    return this.patch<Admin, { role: string }>({ role }, `/${adminId}/role`)
  }

  // Get admin statistics
  async getAdminStats(): Promise<AdminStats> {
    return this.get<AdminStats>('/stats')
  }

  // Get admin activity log
  async getAdminActivity(adminId: string): Promise<any[]> {
    return this.get<any[]>(`/${adminId}/activity`)
  }

  // Get all admin activity logs
  async getAllAdminActivities(params?: { page?: number; limit?: number }): Promise<any> {
    const queryParams = new URLSearchParams()
    
    if (params) {
      Object.entries(params).forEach(([key, value]) => {
        if (value !== undefined) {
          queryParams.append(key, value.toString())
        }
      })
    }
    
    const queryString = queryParams.toString()
    const endpoint = `/activities${queryString ? `?${queryString}` : ''}`
    
    return this.get<any>(endpoint)
  }

  // Get available permissions
  async getPermissions(): Promise<Permission[]> {
    return this.get<Permission[]>('/permissions')
  }

  // Update admin permissions
  async updateAdminPermissions(adminId: string, permissions: string[]): Promise<Admin> {
    return this.patch<Admin, { permissions: string[] }>({ permissions }, `/${adminId}/permissions`)
  }

  // Resend invitation
  async resendInvitation(invitationId: string): Promise<{ message: string }> {
    return this.post<{ message: string }, {}>({}, `/invitations/${invitationId}/resend`)
  }

  // Cancel invitation
  async cancelInvitation(invitationId: string): Promise<{ message: string }> {
    return this.delete<{ message: string }>(`/invitations/${invitationId}`)
  }

  // Get pending invitations
  async getPendingInvitations(): Promise<any[]> {
    return this.get<any[]>('/invitations/pending')
  }

  // Accept invitation (for invited admin)
  async acceptInvitation(token: string, password: string): Promise<{ message: string; admin: Admin }> {
    return this.post<{ message: string; admin: Admin }, { token: string; password: string }>(
      { token, password },
      '/invitations/accept'
    )
  }

  // Bulk operations
  async bulkUpdateAdmins(adminIds: string[], updates: UpdateAdminData): Promise<{ message: string; updatedCount: number }> {
    return this.patch<{ message: string; updatedCount: number }, { adminIds: string[]; updates: UpdateAdminData }>(
      { adminIds, updates },
      '/bulk-update'
    )
  }

  async bulkDeleteAdmins(adminIds: string[]): Promise<{ message: string; deletedCount: number }> {
    return this.post<{ message: string; deletedCount: number }, { adminIds: string[] }>(
      { adminIds },
      '/bulk-delete'
    )
  }

  // Export admins
  async exportAdmins(params?: AdminListParams): Promise<Blob> {
    const queryParams = new URLSearchParams()
    
    if (params) {
      Object.entries(params).forEach(([key, value]) => {
        if (value !== undefined) {
          queryParams.append(key, value.toString())
        }
      })
    }
    
    const queryString = queryParams.toString()
    const endpoint = `/export${queryString ? `?${queryString}` : ''}`
    
    const response = await this.client.get(`${this.baseEndpoint}${endpoint}`, {
      responseType: 'blob'
    })
    
    return response.data
  }
}

// Export singleton instance
export const adminService = new AdminService()
export default adminService