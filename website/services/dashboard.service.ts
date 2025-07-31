// services/dashboard.service.ts

import { BaseService } from './config/api.config'


interface DashboardMetric {
  value: number
  change: number
  changeType: 'increase' | 'decrease' | 'same'
}

interface RecentActivity {
  id: string
  type: string
  user: string
  description: any 
  timeAgo: string
}

interface QuickInsights {
  premiumConversionRate: number
  activeUsersToday: number
  pendingInvitations: number
}

interface MonthlyRegistration {
  month: string
  count: number
}

export interface DashboardResponse {
  success: boolean
  message: string
  data: {
    totalUsers: DashboardMetric
    premiumSubscribers: DashboardMetric
    recentActivity: RecentActivity[]
    quickInsights: QuickInsights
    lastUpdated: string
    MonthleyRegistrations: MonthlyRegistration[]
  }
  timestamp: string
}

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