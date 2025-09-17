// Central API Types File
// This file contains all API-related type definitions to ensure consistency across services

import { ReactElement } from 'react'

// Base API Response Types
export interface BaseApiResponse {
  success: boolean
  message: string
  timestamp: string
}

export interface PaginatedResponse<T> {
  data: T[]
  total: number
  page: number
  page_size: number
  total_pages: number
}

// User Types (Based on admin.md)
export interface ApiUser {
  id: string
  name: string
  email: string
  plan_type: 'free' | 'yefe_plus'
  status: 'active' | 'suspended'
  last_login: string | null
  created_at: string
  updated_at: string
}

export interface UserListResponse extends BaseApiResponse {
  data: {
    users: ApiUser[]
    total: number
    page: number
    page_size: number
    total_pages: number
  }
}

export interface UserListParams {
  email?: string
  status?: 'active' | 'suspended'
  plan?: 'free' | 'yefe_plus'
  limit?: number
  offset?: number
  page?: number
  search?: string
  sort_by?: string
  sort_order?: 'asc' | 'desc'
}

export interface UpdateUserStatusRequest {
  status: 'suspend' | 'active'
}

export interface UpdateUserPlanRequest {
  plan: 'free' | 'yefe_plus'
}

export interface CreateUserRequest {
  name: string
  email: string
  password: string
  plan_type?: 'free' | 'yefe_plus'
}

export interface UpdateUserRequest {
  name?: string
  email?: string
  plan_type?: 'free' | 'yefe_plus'
  status?: 'active' | 'suspended'
}

// Admin Types (Based on admin.md)
export interface AdminInvitation {
  id: string
  email: string
  status: 'pending'
  expires_at: string
}

export interface InviteAdminRequest {
  email: string
}

export interface AdminListResponse extends BaseApiResponse {
  data: {
    users: ApiUser[]
  }
}

// Dashboard Types (Based on dashboard.md)
export interface DashboardMetric {
  value: number
  change: number
  changeType: 'increase' | 'decrease' | 'same'
}

export interface RecentActivity {
  id: string
  type: string
  user: string
  description: any
  timeAgo: string
}

export interface QuickInsights {
  premiumConversionRate: number
  activeUsersToday: number
  pendingInvitations: number
}

export interface MonthlyRegistration {
  month: string
  count: number
}

export interface DashboardData {
  totalUsers: DashboardMetric
  premiumSubscribers: DashboardMetric
  recentActivity: RecentActivity[]
  quickInsights: QuickInsights
  lastUpdated: string
  MonthleyRegistrations: MonthlyRegistration[]
}

export interface DashboardResponse extends BaseApiResponse {
  data: DashboardData
}

// UI Component Types (existing)
export interface Stat {
  title: string
  value: string
  change: string
  trend: 'up' | 'down'
  description: string
  icon: React.ElementType
}

export interface ActivityT {
  type: string
  email?: string
  description?: string
  time: string
}

export interface Insight {
  title: string
  value: string
}

// Legacy Admin Type (to be deprecated)
export interface Admin {
  id: string
  name?: string
  email: string
  role: 'Admin' | 'Super Admin'
  joinDate: string
  lastLogin: string
  status: 'Active' | 'Suspended'
}

// Legacy User Type (to be deprecated)
export interface User {
  id: string
  name: string
  email: string
  plan: 'Free' | 'Yefa+'
  joinDate: string
  lastLogin: string
  status: 'Active' | 'Suspended' | 'Inactive'
  avatar?: string
}

export interface UserManagementData {
  users: User[]
  totalUsers: number
  activeUsers: number
  suspendedUsers: number
}

// Common Error Types
export interface ApiError {
  success: false
  message: string
  errors?: Record<string, string[]>
  timestamp: string
}

// Authentication Types
export interface AuthUser {
  id: string
  name: string
  email: string
  role?: string
}

export interface LoginRequest {
  email: string
  password: string
}

export interface LoginResponse extends BaseApiResponse {
  token: string
  user: AuthUser
}

export interface RegisterRequest {
  name: string
  email: string
  password: string
  confirmPassword: string
}

export interface BackendLoginResponse {
  success: boolean
  message: string
  data: {
    access_token: string
    refresh_token: string
    expires_in: number
  }
  timestamp: string
}

export interface UserProfile {
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

export interface UserResponse {
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
    user_profile: UserProfile
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

export interface AuthResponse {
  user: UserResponse['data']
  token: string
  refreshToken: string
  expiresIn: number
}