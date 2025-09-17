import { BaseService } from './config/api.config'
import type {
  ApiUser,
  AdminListResponse,
  InviteAdminRequest,
  BaseApiResponse
} from '@/lib/types/api'

class AdminService extends BaseService {
  constructor() {
    super('/v1/admin')
  }

  async getAdmins(): Promise<AdminListResponse> {
    return this.get<AdminListResponse>('/admins')
  }

  async inviteAdmin(inviteData: InviteAdminRequest): Promise<BaseApiResponse> {
    return this.post<BaseApiResponse, InviteAdminRequest>(inviteData, '/invite')
  }

  async deleteAdmin(adminId: string): Promise<BaseApiResponse> {
    return this.delete<BaseApiResponse>(`/admins/${adminId}`)
  }

  async acceptInvitation(token: string, password: string): Promise<{ message: string; admin: ApiUser }> {
    return this.post<{ message: string; admin: ApiUser }, { token: string; password: string }>(
      { token, password },
      '/invitations/accept'
    )
  }
}

export const adminService = new AdminService()
export default adminService