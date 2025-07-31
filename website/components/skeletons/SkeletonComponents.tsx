import React from 'react'
import { Card, CardContent, CardHeader } from '@/components/ui/card'

// Base skeleton component with shimmer effect
export const Skeleton = ({ className = "", ...props }: React.HTMLAttributes<HTMLDivElement>) => {
  return (
    <div
      className={`animate-pulse bg-gradient-to-r from-gray-200 via-gray-100 to-gray-200 bg-[length:200%_100%] animate-shimmer rounded ${className}`}
      {...props}
    />
  )
}

// Stat card skeleton
export const StatCardSkeleton = () => {
  return (
    <Card className="shadow-none">
      <CardHeader className="flex flex-row items-center justify-between space-y-0">
        <div className="space-y-2">
          <Skeleton className="h-4 w-24" />
        </div>
        <Skeleton className="h-11 w-11 rounded-full" />
      </CardHeader>
      <CardContent>
        <Skeleton className="h-8 w-20 mb-2" />
        <div className="flex items-center space-x-2">
          <Skeleton className="h-3 w-16" />
          <Skeleton className="h-5 w-12 rounded-md" />
        </div>
      </CardContent>
    </Card>
  )
}

// Activity item skeleton
export const ActivityItemSkeleton = () => {
  return (
    <div className="flex items-start justify-between py-3 border-b border-gray-100 last:border-0">
      <div className="flex-1 space-y-2">
        <Skeleton className="h-4 w-28" />
        <Skeleton className="h-3 w-40" />
      </div>
      <Skeleton className="h-3 w-16" />
    </div>
  )
}

// Insight item skeleton
export const InsightItemSkeleton = () => {
  return (
    <div className="flex items-center justify-between py-3 border-b border-gray-100 last:border-0">
      <Skeleton className="h-4 w-32" />
      <Skeleton className="h-4 w-12" />
    </div>
  )
}

// Complete dashboard skeleton
export const DashboardSkeleton = () => {
  return (
    <div className="p-6 space-y-6 bg-gray-50 min-h-screen">
      {/* Header Skeleton */}
      <div className="space-y-2">
        <Skeleton className="h-8 w-48" />
        <Skeleton className="h-4 w-96" />
      </div>

      {/* Stats Grid Skeleton */}
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-4">
        {Array.from({ length: 4 }).map((_, index) => (
          <StatCardSkeleton key={index} />
        ))}
      </div>

      {/* Activity and Insights Skeleton */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Recent Activity Skeleton */}
        <Card className="shadow-none">
          <CardHeader>
            <div className="space-y-2">
              <Skeleton className="h-6 w-48" />
              <Skeleton className="h-4 w-64" />
            </div>
          </CardHeader>
          <CardContent className="space-y-0">
            {Array.from({ length: 5 }).map((_, index) => (
              <ActivityItemSkeleton key={index} />
            ))}
          </CardContent>
        </Card>

        {/* Quick Insights Skeleton */}
        <Card className="shadow-none">
          <CardHeader>
            <div className="space-y-2">
              <Skeleton className="h-6 w-32" />
              <Skeleton className="h-4 w-64" />
            </div>
          </CardHeader>
          <CardContent className="space-y-0">
            {Array.from({ length: 3 }).map((_, index) => (
              <InsightItemSkeleton key={index} />
            ))}
          </CardContent>
        </Card>
      </div>
    </div>
  )
}

// Loading state with pulse animation for individual components
export const LoadingCard = ({ children, isLoading }: { children: React.ReactNode, isLoading: boolean }) => {
  if (isLoading) {
    return (
      <div className="relative">
        <div className="absolute inset-0 bg-white/50 backdrop-blur-sm z-10 flex items-center justify-center rounded-lg">
          <div className="flex items-center space-x-2">
            <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce [animation-delay:-0.3s]"></div>
            <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce [animation-delay:-0.15s]"></div>
            <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce"></div>
          </div>
        </div>
        <div className="opacity-30">{children}</div>
      </div>
    )
  }
  return <>{children}</>
}

// Error state component
export const ErrorState = ({ 
  error, 
  onRetry, 
  title = "Something went wrong",
  description = "There was an error loading the data. Please try again." 
}: {
  error: string
  onRetry: () => void
  title?: string
  description?: string
}) => {
  return (
    <div className="p-6 space-y-6 bg-gray-50 min-h-screen">
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="text-center max-w-md">
          <div className="mx-auto w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mb-4">
            <svg className="w-8 h-8 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 19c-.77.833.192 2.5 1.732 2.5z" />
            </svg>
          </div>
          <h3 className="text-lg font-semibold text-gray-900 mb-2">{title}</h3>
          <p className="text-gray-600 mb-4">{description}</p>
          <p className="text-sm text-red-600 mb-6 bg-red-50 p-3 rounded-md">{error}</p>
          <div className="space-x-3">
            <button
              onClick={onRetry}
              className="inline-flex items-center px-4 py-2 bg-gray-900 text-white rounded-md hover:bg-gray-800 transition-colors"
            >
              <svg className="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
              </svg>
              Try Again
            </button>
            <button
              onClick={() => window.location.reload()}
              className="inline-flex items-center px-4 py-2 border border-gray-300 text-gray-700 rounded-md hover:bg-gray-50 transition-colors"
            >
              Refresh Page
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}