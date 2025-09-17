'use client'
import React, { useEffect, useState } from 'react'
import toast from 'react-hot-toast'
import { AnalyticsChart } from '@/components/analytics';
import { StatCard } from '@/components/cards/StatCard';
import Challenge from '@/components/icons/Challenge';
import Premium from '@/components/icons/Premium';
import Users from '@/components/icons/Users';
import { Stat } from '@/lib/types';
import { dashboardService } from '@/services/dashboard.service';
import type { DashboardResponse } from '@/lib/types/api';
import { StatCardSkeleton } from '@/components/skeletons/SkeletonComponents';

const transformAnalyticsData = (apiData: DashboardResponse['data'] | any) => {
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

  const getTrend = (changeType: string): "up" | "down" => {
    return changeType === 'increase' ? 'up' : 'down'
  }

  // Helper function to safely get value
  const getValue = (metric: any): number => {
    if (!metric || typeof metric !== 'object') return 0
    return typeof metric.value === 'number' ? metric.value : 0
  }

  // Safe access to nested data with fallbacks - API uses camelCase
  const totalUsers = apiData?.totalUsers || { value: 0, changeType: 'same', change: 0 }
  const premiumSubscribers = apiData?.premiumSubscribers || { value: 0, changeType: 'same', change: 0 }
  const quickInsights = apiData?.quickInsights || {
    premiumConversionRate: 0
  }

  return [
    {
      title: "Total Users",
      value: getValue(totalUsers).toLocaleString(),
      change: getChangePercentage(totalUsers),
      trend: getTrend(totalUsers.changeType || 'same'),
      description: "from last month",
      icon: Users
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
      title: "Premium Conversion Rate",
      value: `${(quickInsights.premiumConversionRate || 0).toFixed(1)}%`,
      change: "+2.1%",
      trend: "up" as const,
      description: "from last month",
      icon: Challenge
    }
  ] as Stat[]
}

const page = () => {
  const [analyticsData, setAnalyticsData] = useState<Stat[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [lastUpdated, setLastUpdated] = useState<string | null>(null)

  const fetchAnalyticsData = async () => {
    try {
      setLoading(true)
      setError(null)

      const response = await dashboardService.getDashboardData()

      if (response && response.success) {
        // Even if data is empty or partially missing, transform it safely
        const transformedData = transformAnalyticsData(response.data || {})
        setAnalyticsData(transformedData)
        setLastUpdated(response.data?.lastUpdated || new Date().toISOString())
      } else {
        throw new Error(response?.message || 'Invalid response format')
      }
    } catch (err: any) {
      const errorMessage = err?.response?.data?.message ||
                          err?.message ||
                          'Failed to load analytics data'

      setError(errorMessage)
      toast.error(errorMessage, {
        duration: 4000,
        position: 'top-right',
      })
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchAnalyticsData()
  }, [])

  return (
    <div className="p-6 space-y-6 bg-gray-50 min-h-screen">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-semibold text-gray-900">Analytics & Reports</h1>
        <div className="flex items-center justify-between mt-1">
          <p className="text-gray-600">Comprehensive insights into user behavior and content performance</p>
          {lastUpdated && (
            <p className="text-xs text-gray-400">
              Last updated: {new Date(lastUpdated).toLocaleString()}
            </p>
          )}
        </div>

        {/* Refresh button */}
        <div className="mt-2">
          <button
            onClick={fetchAnalyticsData}
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

      {/* Stats Grid - Only 3 functional cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
        {loading && analyticsData.length === 0 ? (
          Array.from({ length: 3 }).map((_, index) => (
            <StatCardSkeleton key={index} />
          ))
        ) : (
          analyticsData.map((stat, index) => (
            <StatCard key={index} stat={stat} />
          ))
        )}
      </div>

      {/* Error state */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4">
          <div className="flex items-start">
            <svg className="w-5 h-5 text-red-400 mt-0.5 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <div className="flex-1">
              <h3 className="text-sm font-medium text-red-800">Error Loading Analytics</h3>
              <p className="text-xs text-red-700 mt-1">{error}</p>
              <button
                onClick={fetchAnalyticsData}
                className="text-xs text-red-800 underline hover:text-red-900 mt-2"
              >
                Try again
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Analytics Chart Section */}
      <AnalyticsChart />
    </div>
  )
}

export default page