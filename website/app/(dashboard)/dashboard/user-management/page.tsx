'use client'
import React, { useState, useEffect } from 'react'
import toast from 'react-hot-toast'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { Eye, User as UserIcon, ChevronUp, ChevronDown, RefreshCw, CrownIcon, ChevronLeft, ChevronRight, Shield, ShieldOff } from 'lucide-react'
import type { User } from '@/lib/types'
import UserModal from '@/components/modals/UserModal'
import { userService } from '@/services/user.service'
import type { ApiUser } from '@/lib/types/api'
import { 
  UserManagementSkeleton,
  EmptyUsersState
} from '@/components/skeletons/UserTableSkeleton'
import CustomSearchInput from '@/components/CustomSearchInput'


// Transform API user to component User type
const transformApiUser = (apiUser: ApiUser): User => {
  return {
    id: apiUser.id,
    name: apiUser.name,
    email: apiUser.email,
    plan: apiUser.plan_type === 'free' ? 'Free' : 'Yefa+',
    joinDate: new Date(apiUser.created_at).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    }),
    lastLogin: apiUser.last_login 
      ? new Date(apiUser.last_login).toLocaleDateString('en-US', {
          year: 'numeric',
          month: 'short',
          day: 'numeric'
        })
      : 'Never',
    status: (apiUser.status || 'Active') as 'Active' | 'Suspended' | 'Inactive'
  }
}

type SortField = 'name' | 'email' | 'plan' | 'joinDate' | 'lastLogin' | 'status'
type SortDirection = 'asc' | 'desc'

const StatusBadge: React.FC<{ status: User['status'] }> = ({ status }) => {
  const getVariant = (): "active" | "suspended" | "secondary" => {
    switch (status) {
      case 'Active':
        return 'active'
      case 'Suspended':
        return 'suspended'
      case 'Inactive':
        return 'secondary'
      default:
        return 'secondary'
    }
  }

  return <Badge variant={getVariant()}>{status}</Badge>
}

const PlanBadge: React.FC<{ plan: User['plan'] }> = ({ plan }) => {
  return (
    <div className="flex items-center">
      {plan === 'Yefa+' && <CrownIcon className='mr-1' />}
      <span>{plan}</span>
    </div>
  )
}

const SortableHeader: React.FC<{
  field: SortField;
  currentSort: SortField | null;
  direction: SortDirection;
  onSort: (field: SortField) => void;
  children: React.ReactNode;
}> = ({ field, currentSort, direction, onSort, children }) => {
  return (
    <TableHead 
      className="cursor-pointer hover:bg-gray-50 select-none"
      onClick={() => onSort(field)}
    >
      <div className="flex items-center justify-between">
        {children}
        {currentSort === field && (
          direction === 'asc' ? 
            <ChevronUp className="w-4 h-4" /> : 
            <ChevronDown className="w-4 h-4" />
        )}
      </div>
    </TableHead>
  )
}

export default function UserManagement() {
  const [allUsers, setAllUsers] = useState<User[]>([])
  const [filteredUsers, setFilteredUsers] = useState<User[]>([])
  const [paginatedUsers, setPaginatedUsers] = useState<User[]>([])
  const [loading, setLoading] = useState(true)
  const [refreshing, setRefreshing] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [sortField, setSortField] = useState<SortField | null>(null)
  const [sortDirection, setSortDirection] = useState<SortDirection>('asc')
  const [searchQuery, setSearchQuery] = useState('')
  const [currentPage, setCurrentPage] = useState(1)
  const [itemsPerPage, setItemsPerPage] = useState(10)
  const [suspendingUsers, setSuspendingUsers] = useState<Set<string>>(new Set())

  // Fetch all users from API
  const fetchUsers = async () => {
    try {
      setLoading(true)
      setError(null)

      const response = await userService.getUsers({ page: 1, limit: 1000 })

      if (response && response.success && response.data) {
        const transformedUsers = response.data.users.map(transformApiUser)
        setAllUsers(transformedUsers)
        
        // toast.success('Users loaded successfully', {
        //   duration: 2000,
        //   position: 'top-right',
        // })
      } else {
        throw new Error(response?.message || 'Invalid response format')
      }
    } catch (err: any) {
      const errorMessage = err?.response?.data?.message || 
                          err?.message || 
                          'Failed to load users'
      
      setError(errorMessage)
      toast.error(errorMessage, {
        duration: 4000,
        position: 'top-right',
      })
    } finally {
      setLoading(false)
    }
  }

  // Refresh data
  const refreshData = async () => {
    try {
      setRefreshing(true)
      
      const response = await userService.getUsers({ page: 1, limit: 1000 })

      if (response && response.success && response.data) {
        const transformedUsers = response.data.users.map(transformApiUser)
        setAllUsers(transformedUsers)
        
        toast.success('Data refreshed successfully', {
          duration: 2000,
          position: 'top-right',
        })
      }
    } catch (err: any) {
      const errorMessage = err?.response?.data?.message || 
                          err?.message || 
                          'Failed to refresh data'
      
      toast.error(errorMessage, {
        duration: 4000,
        position: 'top-right',
      })
    } finally {
      setRefreshing(false)
    }
  }

  // Handle user suspension/activation
  const handleUserStatusToggle = async (userId: string, currentStatus: User['status']) => {
    try {
      setSuspendingUsers(prev => new Set(prev).add(userId))

      const newStatus = currentStatus === 'Active' ? 'suspend' : 'active'
      await userService.updateUserStatus(userId, { status: newStatus })

      // Update the user in the local state
      setAllUsers(prev =>
        prev.map(user =>
          user.id === userId
            ? { ...user, status: newStatus === 'suspend' ? 'Suspended' : 'Active' }
            : user
        )
      )

      toast.success(
        `User ${newStatus === 'suspend' ? 'suspended' : 'activated'} successfully`,
        {
          duration: 3000,
          position: 'top-right',
        }
      )
    } catch (err: any) {
      const errorMessage = err?.response?.data?.message ||
                          err?.message ||
                          `Failed to ${currentStatus === 'Active' ? 'suspend' : 'activate'} user`

      toast.error(errorMessage, {
        duration: 4000,
        position: 'top-right',
      })
    } finally {
      setSuspendingUsers(prev => {
        const newSet = new Set(prev)
        newSet.delete(userId)
        return newSet
      })
    }
  }

  useEffect(() => {
    let filtered = [...allUsers]

    // Apply search filter
    if (searchQuery.trim()) {
      const query = searchQuery.toLowerCase()
      filtered = filtered.filter(user => 
        user.name.toLowerCase().includes(query) ||
        user.email.toLowerCase().includes(query)
      )
    }

    // Apply sorting
    if (sortField) {
      filtered.sort((a, b) => {
        const aValue = a[sortField]
        const bValue = b[sortField]
        
        if (sortDirection === 'asc') {
          return aValue > bValue ? 1 : -1
        } else {
          return aValue < bValue ? 1 : -1
        }
      })
    }

    setFilteredUsers(filtered)
    // Reset to first page when filters change
    setCurrentPage(1)
  }, [allUsers, searchQuery, sortField, sortDirection])

  // Pagination effect
  useEffect(() => {
    const startIndex = (currentPage - 1) * itemsPerPage
    const endIndex = startIndex + itemsPerPage
    setPaginatedUsers(filteredUsers.slice(startIndex, endIndex))
  }, [filteredUsers, currentPage, itemsPerPage])


  // Initial data fetch
  useEffect(() => {
    fetchUsers()
  }, [])

  const handleSort = (field: SortField): void => {
    if (sortField === field) {
      setSortDirection(sortDirection === 'asc' ? 'desc' : 'asc')
    } else {
      setSortField(field)
      setSortDirection('asc')
    }
  }

  // Pagination helpers
  const totalPages = Math.ceil(filteredUsers.length / itemsPerPage)
  const startIndex = (currentPage - 1) * itemsPerPage + 1
  const endIndex = Math.min(currentPage * itemsPerPage, filteredUsers.length)

  const handlePageChange = (page: number) => {
    setCurrentPage(page)
  }

  const handleItemsPerPageChange = (newItemsPerPage: number) => {
    setItemsPerPage(newItemsPerPage)
    setCurrentPage(1)
  }

  // Error state
  if (error && allUsers.length === 0) {
    return (
      <div className="p-6 space-y-6 bg-gray-50 min-h-screen">
        <div className="flex items-center justify-center min-h-[400px]">
          <div className="text-center max-w-md">
            <div className="mx-auto w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mb-4">
              <svg className="w-8 h-8 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 19c-.77.833.192 2.5 1.732 2.5z" />
              </svg>
            </div>
            <h3 className="text-lg font-semibold text-gray-900 mb-2">Failed to Load Users</h3>
            <p className="text-gray-600 mb-4">We couldn't load the user data.</p>
            <p className="text-sm text-red-600 mb-6 bg-red-50 p-3 rounded-md">{error}</p>
            <button
              onClick={fetchUsers}
              className="inline-flex items-center px-4 py-2 bg-gray-900 text-white rounded-md hover:bg-gray-800 transition-colors"
            >
              Try Again
            </button>
          </div>
        </div>
      </div>
    )
  }

  // Loading state
  if (loading) {
    return <UserManagementSkeleton />
  }

  return (
    <div className="p-3 md:p-6 space-y-4 md:space-y-6 bg-gray-50 min-h-screen animate-fadeIn">
      {/* Header */}
      <div>
        <h1 className="text-xl md:text-2xl font-semibold text-gray-900">User Management</h1>
        <p className="text-gray-600 mt-1 text-sm md:text-base">Manage user accounts, subscriptions, and activity</p>
      </div>

      {/* Search Bar */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div className="flex-1 max-w-md">
          <CustomSearchInput
            placeholder="Search users..."
            value={searchQuery}
            onChange={setSearchQuery}
            width="100%"
          />
        </div>
        
        <Button 
          variant="outline" 
          onClick={refreshData}
          disabled={refreshing}
          size="sm"
          className="w-full sm:w-auto"
        >
          <RefreshCw className={`w-4 h-4 mr-2 ${refreshing ? 'animate-spin' : ''}`} />
          {refreshing ? 'Refreshing...' : 'Refresh'}
        </Button>
      </div>

      {/* Users Table/Cards */}
      <Card className="shadow-none px-2 md:px-4">
        <CardHeader>
          <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
            <div>
              <CardTitle className="text-lg font-semibold text-gray-900">All Users</CardTitle>
              <p className="text-sm text-gray-600 mt-1">
                Showing {filteredUsers.length > 0 ? startIndex : 0}-{endIndex} of {filteredUsers.length} users
                {searchQuery && ` (filtered by "${searchQuery}")`}
              </p>
            </div>
            <div className="flex items-center space-x-2">
              <label htmlFor="itemsPerPage" className="text-sm text-gray-600 hidden sm:block">Show:</label>
              <select
                id="itemsPerPage"
                value={itemsPerPage}
                onChange={(e) => handleItemsPerPageChange(Number(e.target.value))}
                className="border border-gray-300 rounded-md px-2 py-1 text-sm"
              >
                <option value={5}>5</option>
                <option value={10}>10</option>
                <option value={25}>25</option>
                <option value={50}>50</option>
                <option value={100}>100</option>
              </select>
              <span className="text-sm text-gray-600 hidden sm:block">per page</span>
            </div>
          </div>
        </CardHeader>
        <CardContent className="p-0">
          <div className="overflow-x-auto scrollbar-thin scrollbar-thumb-gray-300 scrollbar-track-gray-100">
            <Table className="min-w-full">
              <TableHeader>
                <TableRow>
                  <SortableHeader 
                    field="name" 
                    currentSort={sortField} 
                    direction={sortDirection} 
                    onSort={handleSort}
                  >
                    NAME
                  </SortableHeader>
                  <SortableHeader 
                    field="email" 
                    currentSort={sortField} 
                    direction={sortDirection} 
                    onSort={handleSort}
                  >
                    EMAIL
                  </SortableHeader>
                  <SortableHeader 
                    field="plan" 
                    currentSort={sortField} 
                    direction={sortDirection} 
                    onSort={handleSort}
                  >
                    PLAN
                  </SortableHeader>
                  <SortableHeader 
                    field="joinDate" 
                    currentSort={sortField} 
                    direction={sortDirection} 
                    onSort={handleSort}
                  >
                    JOIN DATE
                  </SortableHeader>
                  <SortableHeader 
                    field="lastLogin" 
                    currentSort={sortField} 
                    direction={sortDirection} 
                    onSort={handleSort}
                  >
                    LAST LOGIN
                  </SortableHeader>
                  <SortableHeader 
                    field="status" 
                    currentSort={sortField} 
                    direction={sortDirection} 
                    onSort={handleSort}
                  >
                    STATUS
                  </SortableHeader>
                  <TableHead>ACTIONS</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {paginatedUsers.length > 0 ? (
                  paginatedUsers.map((user) => (
                    <TableRow key={user.id} className="hover:bg-gray-50">
                      <TableCell className="font-medium whitespace-nowrap">{user.name}</TableCell>
                      <TableCell className="text-gray-600 whitespace-nowrap">{user.email}</TableCell>
                      <TableCell className="whitespace-nowrap">
                        <PlanBadge plan={user.plan} />
                      </TableCell>
                      <TableCell className="text-gray-600 whitespace-nowrap">{user.joinDate}</TableCell>
                      <TableCell className="text-gray-600 whitespace-nowrap">{user.lastLogin}</TableCell>
                      <TableCell className="whitespace-nowrap">
                        <StatusBadge status={user.status} />
                      </TableCell>
                      <TableCell className="whitespace-nowrap">
                        <div className="flex items-center space-x-2">
                          <Button variant="ghost" size="sm">
                            <Eye className="w-4 h-4" />
                          </Button>
                          <UserModal
                            user={user}
                            onStatusToggle={handleUserStatusToggle}
                            isLoading={suspendingUsers.has(user.id)}
                          >
                            <Button variant="ghost" size="sm">
                              <UserIcon className="w-4 h-4" />
                            </Button>
                          </UserModal>
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => handleUserStatusToggle(user.id, user.status)}
                            disabled={suspendingUsers.has(user.id)}
                            className={`${
                              user.status === 'Active'
                                ? 'text-red-600 hover:text-red-700 hover:bg-red-50'
                                : 'text-green-600 hover:text-green-700 hover:bg-green-50'
                            }`}
                            title={user.status === 'Active' ? 'Suspend user' : 'Activate user'}
                          >
                            {suspendingUsers.has(user.id) ? (
                              <RefreshCw className="w-4 h-4 animate-spin" />
                            ) : user.status === 'Active' ? (
                              <ShieldOff className="w-4 h-4" />
                            ) : (
                              <Shield className="w-4 h-4" />
                            )}
                          </Button>
                        </div>
                      </TableCell>
                    </TableRow>
                  ))
                ) : (
                  <TableRow>
                    <TableCell colSpan={7}>
                      {searchQuery ? (
                        <div className="flex flex-col items-center justify-center py-12 px-4">
                          <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mb-4">
                            <svg className="w-8 h-8 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                            </svg>
                          </div>
                          <h3 className="text-lg font-semibold text-gray-900 mb-2">No results found</h3>
                          <p className="text-gray-600 text-center mb-4">
                            No users found matching "{searchQuery}". Try a different search term.
                          </p>
                          <button
                            onClick={() => setSearchQuery('')}
                            className="inline-flex items-center px-4 py-2 bg-gray-900 text-white rounded-md hover:bg-gray-800 transition-colors text-sm"
                          >
                            Clear search
                          </button>
                        </div>
                      ) : (
                        <EmptyUsersState />
                      )}
                    </TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </div>
          {/* Pagination Controls */}
          {filteredUsers.length > 0 && totalPages > 1 && (
            <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 px-3 md:px-4 py-4 border-t">
              <div className="text-sm text-gray-600 text-center sm:text-left">
                Showing {startIndex} to {endIndex} of {filteredUsers.length} results
              </div>
              <div className="flex items-center justify-center space-x-1">
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => handlePageChange(currentPage - 1)}
                  disabled={currentPage === 1}
                  className="px-2"
                >
                  <ChevronLeft className="w-4 h-4" />
                  <span className="hidden sm:inline ml-1">Previous</span>
                </Button>
                
                <div className="flex items-center space-x-1">
                  {/* Page numbers */}
                  <div className="hidden sm:flex items-center space-x-1">
                    {Array.from({ length: Math.min(5, totalPages) }, (_, i) => {
                      let pageNum
                      if (totalPages <= 5) {
                        pageNum = i + 1
                      } else if (currentPage <= 3) {
                        pageNum = i + 1
                      } else if (currentPage >= totalPages - 2) {
                        pageNum = totalPages - 4 + i
                      } else {
                        pageNum = currentPage - 2 + i
                      }
                      
                      return (
                        <Button
                          key={pageNum}
                          variant={currentPage === pageNum ? "default" : "outline"}
                          size="sm"
                          onClick={() => handlePageChange(pageNum)}
                          className="w-8 h-8 p-0"
                        >
                          {pageNum}
                        </Button>
                      )
                    })}
                  </div>
                  
                  {/* Mobile: Just show current page */}
                  <div className="sm:hidden">
                    <span className="text-sm text-gray-600">
                      Page {currentPage} of {totalPages}
                    </span>
                  </div>
                </div>
                
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => handlePageChange(currentPage + 1)}
                  disabled={currentPage === totalPages}
                  className="px-2"
                >
                  <span className="hidden sm:inline mr-1">Next</span>
                  <ChevronRight className="w-4 h-4" />
                </Button>
              </div>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  )
}