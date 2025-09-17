// services/dashboard.service.ts

import { BaseService } from './config/api.config'
import type { DashboardResponse } from '@/lib/types/api'

class DashboardService extends BaseService {
  constructor() {
    super('/v1/dashboard')
  }

  // Get dashboard data - simple GET request
  async getDashboardData(): Promise<DashboardResponse> {
    return this.get<DashboardResponse>()
  }
}

// Export singleton instance
export const dashboardService = new DashboardService()
export default dashboardService