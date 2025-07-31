import React from 'react'
import { Card, CardContent, CardHeader } from '@/components/ui/card'

// Base skeleton component with shimmer effect
const Skeleton = ({ className = "", ...props }: React.HTMLAttributes<HTMLDivElement>) => {
  return (
    <div
      className={`animate-pulse bg-gradient-to-r from-gray-200 via-gray-100 to-gray-200 bg-[length:200%_100%] animate-shimmer rounded ${className}`}
      {...props}
    />
  )
}

// Search bar skeleton
export const SearchSkeleton = () => {
  return (
    <div className="flex items-center space-x-4 mb-6">
      <div className="flex-1">
        <Skeleton className="h-10 w-full rounded-md" />
      </div>
      <Skeleton className="h-10 w-24 rounded-md" />
      <Skeleton className="h-10 w-20 rounded-md" />
    </div>
  )
}

// Table header skeleton
export const TableHeaderSkeleton = () => {
  return (
    <thead className="bg-gray-50">
      <tr>
        {Array.from({ length: 7 }).map((_, index) => (
          <th key={index} className="px-6 py-3">
            <Skeleton className="h-4 w-16" />
          </th>
        ))}
      </tr>
    </thead>
  )
}

// Table row skeleton
export const TableRowSkeleton = () => {
  return (
    <tr className="hover:bg-gray-50 border-b border-gray-200">
      <td className="px-6 py-4">
        <Skeleton className="h-4 w-32" />
      </td>
      <td className="px-6 py-4">
        <Skeleton className="h-4 w-48" />
      </td>
      <td className="px-6 py-4">
        <div className="flex items-center">
          <Skeleton className="h-5 w-12 rounded-full" />
        </div>
      </td>
      <td className="px-6 py-4">
        <Skeleton className="h-4 w-24" />
      </td>
      <td className="px-6 py-4">
        <Skeleton className="h-4 w-24" />
      </td>
      <td className="px-6 py-4">
        <Skeleton className="h-5 w-16 rounded-full" />
      </td>
      <td className="px-6 py-4">
        <div className="flex items-center space-x-2">
          <Skeleton className="h-8 w-8 rounded" />
          <Skeleton className="h-8 w-8 rounded" />
        </div>
      </td>
    </tr>
  )
}

// Complete user management skeleton
export const UserManagementSkeleton = () => {
  return (
    <div className="p-6 space-y-6 bg-gray-50 min-h-screen">
      {/* Header Skeleton */}
      <div className="space-y-2">
        <Skeleton className="h-8 w-64" />
        <Skeleton className="h-4 w-96" />
      </div>

      {/* Search and filters skeleton */}
      <SearchSkeleton />

      {/* Table skeleton */}
      <Card className="shadow-none">
        <CardHeader>
          <div className="flex items-center justify-between">
            <div className="space-y-2">
              <Skeleton className="h-6 w-32" />
              <Skeleton className="h-4 w-48" />
            </div>
            <Skeleton className="h-4 w-24" />
          </div>
        </CardHeader>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <TableHeaderSkeleton />
              <tbody className="bg-white divide-y divide-gray-200">
                {Array.from({ length: 8 }).map((_, index) => (
                  <TableRowSkeleton key={index} />
                ))}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>

      {/* Pagination skeleton */}
      <div className="flex items-center justify-between">
        <Skeleton className="h-4 w-48" />
        <div className="flex space-x-2">
          <Skeleton className="h-8 w-20 rounded" />
          <Skeleton className="h-8 w-8 rounded" />
          <Skeleton className="h-8 w-8 rounded" />
          <Skeleton className="h-8 w-8 rounded" />
          <Skeleton className="h-8 w-20 rounded" />
        </div>
      </div>
    </div>
  )
}

// Loading overlay for table
export const TableLoadingOverlay = ({ children, isLoading }: { children: React.ReactNode, isLoading: boolean }) => {
  if (isLoading) {
    return (
      <div className="relative">
        <div className="absolute inset-0 bg-white/60 backdrop-blur-sm z-10 flex items-center justify-center">
          <div className="flex flex-col items-center space-y-3">
            <div className="flex items-center space-x-2">
              <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce [animation-delay:-0.3s]"></div>
              <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce [animation-delay:-0.15s]"></div>
              <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce"></div>
            </div>
            <span className="text-sm text-gray-600 font-medium">Loading users...</span>
          </div>
        </div>
        <div className="opacity-30">{children}</div>
      </div>
    )
  }
  return <>{children}</>
}

// Empty state component
export const EmptyUsersState = ({ onReset }: { onReset?: () => void }) => {
  return (
    <div className="flex flex-col items-center justify-center py-12 px-4">
      <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mb-4">
        <svg className="w-8 h-8 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
        </svg>
      </div>
      <h3 className="text-lg font-semibold text-gray-900 mb-2">No users found</h3>
      <p className="text-gray-600 text-center mb-4">
        We couldn't find any users matching your criteria.
      </p>
      {onReset && (
        <button
          onClick={onReset}
          className="inline-flex items-center px-4 py-2 bg-gray-900 text-white rounded-md hover:bg-gray-800 transition-colors text-sm"
        >
          Clear filters
        </button>
      )}
    </div>
  )
}