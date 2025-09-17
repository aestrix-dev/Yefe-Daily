'use client'
import React, { useEffect, useState } from 'react'
import toast from 'react-hot-toast'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { StatCard } from '@/components/cards/StatCard'
import { ActivityT, Insight, Stat } from '@/lib/types'
import ActivityItem from '@/components/activity'
import InsightItem from '@/components/insight'
import Users from '@/components/icons/Users'
import Premium from '@/components/icons/Premium'
import Daily from '@/components/icons/Daily'
import Challenge from '@/components/icons/Challenge'
import { dashboardService } from '@/services/dashboard.service'
import type { DashboardResponse } from '@/lib/types/api'
import { authService } from '@/services/auth.service'
import { 
  DashboardSkeleton, 
  ErrorState, 
  LoadingCard,
  StatCardSkeleton,
  ActivityItemSkeleton,
  InsightItemSkeleton
} from '@/components/skeletons/SkeletonComponents'

// Transform API data to match component structure
const transformDashboardData = (apiData: DashboardResponse['data'] | any) => {
  // Handle completely null/undefined apiData
  if (!apiData || typeof apiData !== 'object') {
    apiData = {}
  }
  // Helper function to safely get change percentage
  const getChangePercentage = (metric: any) => {
    if (!metric || typeof metric !== 'object') return '0.0%'
    if (metric.changeType === 'same' || !metric.change) return '0.0%'
    const sign = metric.changeType === 'increase' ? '+' : '-'
    const changeValue = typeof metric.change === 'number' ? metric.change : 0
    return `${sign}${Math.abs(changeValue * 100).toFixed(1)}%`
  }

  // Helper function to safely get trend
  const getTrend = (changeType: string): "up" | "down" => {
    return changeType === 'increase' ? 'up' : 'down'
  }

  // Helper function to safely get value
  const getValue = (metric: any): number => {
    if (!metric || typeof metric !== 'object') return 0
    return typeof metric.value === 'number' ? metric.value : 0
  }

  // Helper function to format description
  const formatDescription = (desc: any): string => {
    if (typeof desc === 'string') return desc
    if (typeof desc === 'object' && desc !== null) {
      return desc.message || 'Activity logged'
    }
    return 'Activity logged'
  }

  // Safe access to nested data with fallbacks - API uses camelCase
  const totalUsers = apiData?.totalUsers || { value: 0, changeType: 'same', change: 0 }
  const premiumSubscribers = apiData?.premiumSubscribers || { value: 0, changeType: 'same', change: 0 }
  const quickInsights = apiData?.quickInsights || {
    activeUsersToday: 0,
    premiumConversionRate: 0,
    pendingInvitations: 0
  }
  const recentActivity = apiData?.recentActivity || []

  return {
    stats: [
      {
        title: "Total Users",
        value: getValue(totalUsers).toLocaleString(),
        change: getChangePercentage(totalUsers),
        trend: getTrend(totalUsers.changeType || 'same'),
        description: "from last month",
        icon: Users
      },
      {
        title: "Daily Active Users",
        value: (quickInsights.activeUsersToday || 0).toLocaleString(),
        change: "+3.1%",
        trend: "up" as const,
        description: "from last month",
        icon: Daily
      },
      {
        title: "Premium Subscribers",
        value: getValue(premiumSubscribers).toLocaleString(),
        change: getChangePercentage(premiumSubscribers),
        trend: getTrend(premiumSubscribers.changeType || 'same'),
        description: "from last month",
        icon: Premium
      },
      {
        title: "Conversion Rate",
        value: `${(quickInsights.premiumConversionRate || 0).toFixed(1)}%`,
        change: "+2.1%",
        trend: "up" as const,
        description: "from last month",
        icon: Challenge
      }
    ] as Stat[],
    recentActivity: recentActivity.map((activity: any) => ({
      type: (activity?.type || 'activity').charAt(0).toUpperCase() + (activity?.type || 'activity').slice(1).replace('_', ' '),
      email: activity?.user || 'Unknown user',
      description: formatDescription(activity?.description),
      time: activity?.timeAgo || 'Unknown time'
    })) as ActivityT[],
    quickInsights: [
      {
        title: "Premium Conversion Rate",
        value: `${(quickInsights.premiumConversionRate || 0).toFixed(1)}%`
      },
      {
        title: "Active Users Today",
        value: (quickInsights.activeUsersToday || 0).toLocaleString()
      },
      {
        title: "Pending Invitations",
        value: (quickInsights.pendingInvitations || 0).toString()
      }
    ] as Insight[]
  }
}

export default function Dashboard() {
  const [dashboardData, setDashboardData] = useState<{
    stats: Stat[]
    recentActivity: ActivityT[]
    quickInsights: Insight[]
  } | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [lastUpdated, setLastUpdated] = useState<string | null>(null)
  const [user, setUser] = useState<any>(null)

  // Get user data for personalized greeting
  useEffect(() => {
    const userData = authService.getStoredUser()
    setUser(userData)
  }, [])

  const fetchDashboardData = async () => {
    try {
      setLoading(true)
      setError(null)
      
      const response = await dashboardService.getDashboardData()
      
      if (response && response.success) {
        // Even if data is empty or partially missing, transform it safely
        const transformedData = transformDashboardData(response.data || {})
        setDashboardData(transformedData)
        setLastUpdated(response.data?.lastUpdated || new Date().toISOString())

        // Show success toast only on initial load or retry
        // if (!dashboardData) {
        //   toast.success('Dashboard loaded successfully', {
        //     duration: 2000,
        //     position: 'top-right',
        //   })
        // }
      } else {
        throw new Error(response?.message || 'Invalid response format')
      }
    } catch (err: any) {
      const errorMessage = err?.response?.data?.message || 
                          err?.message || 
                          'Failed to load dashboard data'
      
      setError(errorMessage)
      toast.error(errorMessage, {
        duration: 4000,
        position: 'top-right',
      })
    } finally {
      setLoading(false)
    }
  }

  // Initial data fetch
  useEffect(() => {
    fetchDashboardData()
  }, [])

  // Auto-refresh every 5 minutes
  useEffect(() => {
    const interval = setInterval(() => {
      if (!loading) {
        fetchDashboardData()
      }
    }, 5 * 60 * 1000) 

    return () => clearInterval(interval)
  }, [loading])

  // Error state
  if (error && !dashboardData) {
    return (
      <ErrorState
        error={error}
        onRetry={fetchDashboardData}
        title="Dashboard Unavailable"
        description="We couldn't load your dashboard data."
      />
    )
  }

  // Loading state
  if (loading && !dashboardData) {
    return <DashboardSkeleton />
  }

  return (
    <div className="p-6 space-y-6 bg-gray-50 min-h-screen animate-fadeIn">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-semibold text-gray-900">
          Dashboard
         
        </h1>
        <div className="flex items-center justify-between mt-1">
          <p className="text-gray-600">Here's what's happening with Yafa today.</p>
          {lastUpdated && (
            <p className="text-xs text-gray-400">
              Last updated: {new Date(lastUpdated).toLocaleString()}
            </p>
          )}
        </div>
        
        {/* Refresh button */}
        <div className="mt-2">
          <button
            onClick={fetchDashboardData}
            disabled={loading}
            className="inline-flex items-center px-3 py-1 text-xs bg-white border border-gray-200 rounded-md hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            <svg 
              className={`w-3 h-3 mr-1 ${loading ? 'animate-spin' : ''}`} 
              fill="none" 
              stroke="currentColor" 
              viewBox="0 0 24 24"
            >
              <path 
                strokeLinecap="round" 
                strokeLinejoin="round" 
                strokeWidth={2} 
                d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" 
              />
            </svg>
            {loading ? 'Updating...' : 'Refresh'}
          </button>
        </div>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-4">
        {dashboardData ? (
          dashboardData.stats.map((stat, index) => (
            <LoadingCard key={index} isLoading={loading}>
              <StatCard stat={stat} />
            </LoadingCard>
          ))
        ) : (
          Array.from({ length: 4 }).map((_, index) => (
            <StatCardSkeleton key={index} />
          ))
        )}
      </div>

      {/* Activity and Insights */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Recent User Activity */}
        <LoadingCard isLoading={loading}>
          <Card className="shadow-none">
            <CardHeader>
              <CardTitle className="text-lg font-semibold text-gray-900">
                Recent User Activity
              </CardTitle>
              <CardDescription className="text-gray-600">
                Key metrics and performance indicators
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-0">
              {dashboardData ? (
                dashboardData.recentActivity.length > 0 ? (
                  dashboardData.recentActivity.map((activity, index) => (
                    <ActivityItem key={index} activity={activity} />
                  ))
                ) : (
                  <div className="py-8 text-center text-gray-500">
                    <p>No recent activity to display</p>
                  </div>
                )
              ) : (
                Array.from({ length: 5 }).map((_, index) => (
                  <ActivityItemSkeleton key={index} />
                ))
              )}
            </CardContent>
          </Card>
        </LoadingCard>

        {/* Quick Insights */}
        <LoadingCard isLoading={loading}>
          <Card className="shadow-none">
            <CardHeader>
              <CardTitle className="text-lg font-semibold text-gray-900">
                Quick Insights
              </CardTitle>
              <CardDescription className="text-gray-600">
                Key metrics and performance indicators
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-0">
              {dashboardData ? (
                dashboardData.quickInsights.map((insight, index) => (
                  <InsightItem key={index} insight={insight} />
                ))
              ) : (
                Array.from({ length: 3 }).map((_, index) => (
                  <InsightItemSkeleton key={index} />
                ))
              )}
            </CardContent>
          </Card>
        </LoadingCard>
      </div>

      {/* Error banner for partial failures */}
      {error && dashboardData && (
        <div className="fixed bottom-4 right-4 max-w-sm">
          <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4 shadow-lg">
            <div className="flex items-start">
              <svg className="w-5 h-5 text-yellow-400 mt-0.5 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 19c-.77.833.192 2.5 1.732 2.5z" />
              </svg>
              <div className="flex-1">
                <h3 className="text-sm font-medium text-yellow-800">Update Failed</h3>
                <p className="text-xs text-yellow-700 mt-1">Some data may be outdated</p>
                <button
                  onClick={() => {
                    setError(null)
                    fetchDashboardData()
                  }}
                  className="text-xs text-yellow-800 underline hover:text-yellow-900 mt-2"
                >
                  Try again
                </button>
              </div>
              <button
                onClick={() => setError(null)}
                className="text-yellow-400 hover:text-yellow-600 ml-2"
              >
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}