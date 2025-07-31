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
import { Eye, User as UserIcon, ChevronUp, ChevronDown, RefreshCw, CrownIcon } from 'lucide-react'
import type { User } from '@/lib/types'
import UserModal from '@/components/modals/UserModal'
import { userService, type ApiUser } from '@/services/user.service'
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
  const [loading, setLoading] = useState(true)
  const [refreshing, setRefreshing] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [sortField, setSortField] = useState<SortField | null>(null)
  const [sortDirection, setSortDirection] = useState<SortDirection>('asc')
  const [searchQuery, setSearchQuery] = useState('')

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
  }, [allUsers, searchQuery, sortField, sortDirection])

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
    <div className="p-6 space-y-6 bg-gray-50 min-h-screen animate-fadeIn">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-semibold text-gray-900">User Management</h1>
        <p className="text-gray-600 mt-1">Manage user accounts, subscriptions, and activity</p>
      </div>

      {/* Search Bar */}
      <div className="flex items-center justify-between">
        <CustomSearchInput
          placeholder="Search users by name or email..."
          value={searchQuery}
          onChange={setSearchQuery}
          width="400px"
        />
        
        <Button 
          variant="outline" 
          onClick={refreshData}
          disabled={refreshing}
        >
          <RefreshCw className={`w-4 h-4 mr-2 ${refreshing ? 'animate-spin' : ''}`} />
          {refreshing ? 'Refreshing...' : 'Refresh Data'}
        </Button>
      </div>

      {/* Users Table */}
      <Card className="shadow-none px-4">
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle className="text-lg font-semibold text-gray-900">All Users</CardTitle>
              <p className="text-sm text-gray-600 mt-1">
                Showing {filteredUsers.length} of {allUsers.length} users
                {searchQuery && ` (filtered by "${searchQuery}")`}
              </p>
            </div>
          </div>
        </CardHeader>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <Table>
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
                {filteredUsers.length > 0 ? (
                  filteredUsers.map((user) => (
                    <TableRow key={user.id} className="hover:bg-gray-50">
                      <TableCell className="font-medium">{user.name}</TableCell>
                      <TableCell className="text-gray-600">{user.email}</TableCell>
                      <TableCell>
                        <PlanBadge plan={user.plan} />
                      </TableCell>
                      <TableCell className="text-gray-600">{user.joinDate}</TableCell>
                      <TableCell className="text-gray-600">{user.lastLogin}</TableCell>
                      <TableCell>
                        <StatusBadge status={user.status} />
                      </TableCell>
                      <TableCell>
                        <div className="flex items-center space-x-2">
                          <Button variant="ghost" size="sm">
                            <Eye className="w-4 h-4" />
                          </Button>
                          <UserModal user={user}>
                            <Button variant="ghost" size="sm">
                              <UserIcon className="w-4 h-4" />
                            </Button>
                          </UserModal>
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
        </CardContent>
      </Card>
    </div>
  )
}