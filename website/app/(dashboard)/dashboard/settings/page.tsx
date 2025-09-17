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
import { ChevronUp, ChevronDown, Trash2, Plus, RefreshCw } from 'lucide-react'
import type { Admin } from '@/lib/types'
import type { ApiUser } from '@/lib/types/api'
import InviteAdminModal from '@/components/modals/InviteAdminModal'
import DeleteAdminModal from '@/components/modals/DeleteAdminModal'
import { adminService } from '@/services/admin.service'

// Transform API user to Admin type
const transformApiUserToAdmin = (apiUser: ApiUser): Admin => {
  return {
    id: apiUser.id,
    name: apiUser.name || 'N/A',
    email: apiUser.email,
    role: 'Admin', // All users from /admin/admins are admins
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
    // Handle empty status field - default to Active if empty or missing
    status: (apiUser.status === 'suspended' ? 'Suspended' : 'Active') as 'Active' | 'Suspended'
  }
}

type SortField = 'name' | 'email' | 'role' | 'joinDate' | 'lastLogin' | 'status'
type SortDirection = 'asc' | 'desc'

const StatusBadge: React.FC<{ status: Admin['status'] }> = ({ status }) => {
  const getVariant = () => {
    switch (status) {
      case 'Active':
        return 'active'
      case 'Suspended':
        return 'destructive'
      default:
        return 'secondary'
    }
  }

  return <Badge variant={getVariant()}>{status}</Badge>
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

export default function AdminRoleManagement() {
  const [admins, setAdmins] = useState<Admin[]>([])
  const [loading, setLoading] = useState(true)
  const [refreshing, setRefreshing] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [sortField, setSortField] = useState<SortField | null>(null)
  const [sortDirection, setSortDirection] = useState<SortDirection>('asc')
  const [inviteLoading, setInviteLoading] = useState(false)
  const [deletingAdmins, setDeletingAdmins] = useState<Set<string>>(new Set())

  // Fetch admins from API
  const fetchAdmins = async () => {
    try {
      setLoading(true)
      setError(null)

      const response = await adminService.getAdmins()

      // Handle the nested response structure: response.data.users
      if (response && response.success && response.data && response.data.users) {
        const transformedAdmins = response.data.users.map(transformApiUserToAdmin)
        setAdmins(transformedAdmins)
      } else {
        throw new Error('Invalid response format')
      }
    } catch (err: any) {
      const errorMessage = err?.response?.data?.message ||
                          err?.message ||
                          'Failed to load admins'

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

      const response = await adminService.getAdmins()

      // Handle the nested response structure: response.data.users
      if (response && response.success && response.data && response.data.users) {
        const transformedAdmins = response.data.users.map(transformApiUserToAdmin)
        setAdmins(transformedAdmins)

        toast.success('Data refreshed successfully', {
          duration: 2000,
          position: 'top-right',
        })
      } else {
        throw new Error('Invalid response format')
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

  // Initial data fetch
  useEffect(() => {
    fetchAdmins()
  }, [])

  const handleSort = (field: SortField): void => {
    if (sortField === field) {
      setSortDirection(sortDirection === 'asc' ? 'desc' : 'asc')
    } else {
      setSortField(field)
      setSortDirection('asc')
    }

    const sorted = [...admins].sort((a, b) => {
      const aValue = a[field] ?? ''
      const bValue = b[field] ?? ''
      
      if (sortDirection === 'asc') {
        return aValue > bValue ? 1 : -1
      } else {
        return aValue < bValue ? 1 : -1
      }
    })
    
    setAdmins(sorted)
  }

  const handleInviteAdmin = async (adminData: { email: string; role: string }): Promise<void> => {
    try {
      setInviteLoading(true)

      await adminService.inviteAdmin({ email: adminData.email })

      toast.success('Admin invitation sent successfully', {
        duration: 3000,
        position: 'top-right',
      })

      // Refresh the admin list to get updated data
      await refreshData()
    } catch (err: any) {
      const errorMessage = err?.response?.data?.message ||
                          err?.message ||
                          'Failed to send invitation'

      toast.error(errorMessage, {
        duration: 4000,
        position: 'top-right',
      })
      throw err // Re-throw to let modal handle it
    } finally {
      setInviteLoading(false)
    }
  }

  const handleDeleteAdmin = async (adminId: string): Promise<void> => {
    try {
      setDeletingAdmins(prev => new Set(prev).add(adminId))

      await adminService.deleteAdmin(adminId)

      // Remove admin from local state
      setAdmins(prev => prev.filter(admin => admin.id !== adminId))

      toast.success('Admin deleted successfully', {
        duration: 3000,
        position: 'top-right',
      })
    } catch (err: any) {
      const errorMessage = err?.response?.data?.message ||
                          err?.message ||
                          'Failed to delete admin'

      toast.error(errorMessage, {
        duration: 4000,
        position: 'top-right',
      })
    } finally {
      setDeletingAdmins(prev => {
        const newSet = new Set(prev)
        newSet.delete(adminId)
        return newSet
      })
    }
  }

  return (
    <div className="p-3 md:p-6 space-y-4 md:space-y-6 bg-gray-50 min-h-screen">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mt-4 md:mt-10">
        <div>
          <h1 className="text-xl md:text-2xl font-semibold text-gray-900">Admin Role Management</h1>
          <p className="text-gray-600 mt-1 text-sm md:text-base">Manage administrator access and permissions</p>
        </div>
        <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3">
          <Button
            variant="outline"
            onClick={refreshData}
            disabled={refreshing || loading}
            size="sm"
            className="w-full sm:w-auto"
          >
            <RefreshCw className={`w-4 h-4 mr-2 ${refreshing ? 'animate-spin' : ''}`} />
            {refreshing ? 'Refreshing...' : 'Refresh'}
          </Button>
          <InviteAdminModal
            onInvite={handleInviteAdmin}
            isLoading={inviteLoading}
          >
            <Button
              className="bg-[#374035] hover:bg-[#2d332b] text-white w-full sm:w-auto"
              disabled={inviteLoading}
              size="sm"
            >
              {inviteLoading ? (
                <RefreshCw className="w-4 h-4 mr-2 animate-spin" />
              ) : (
                <Plus className="w-4 h-4 mr-2" />
              )}
              {inviteLoading ? 'Sending...' : 'Invite New Admin'}
            </Button>
          </InviteAdminModal>
        </div>
      </div>

      {/* Admins Table */}
      <Card className="shadow-none">
        <CardContent className="p-2 md:p-4">
          {error && !loading ? (
            <div className="flex items-center justify-center min-h-[400px]">
              <div className="text-center max-w-md">
                <div className="mx-auto w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mb-4">
                  <svg className="w-8 h-8 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 19c-.77.833.192 2.5 1.732 2.5z" />
                  </svg>
                </div>
                <h3 className="text-lg font-semibold text-gray-900 mb-2">Failed to Load Admins</h3>
                <p className="text-gray-600 mb-4">We couldn't load the admin data.</p>
                <p className="text-sm text-red-600 mb-6 bg-red-50 p-3 rounded-md">{error}</p>
                <button
                  onClick={fetchAdmins}
                  className="inline-flex items-center px-4 py-2 bg-gray-900 text-white rounded-md hover:bg-gray-800 transition-colors"
                >
                  Try Again
                </button>
              </div>
            </div>
          ) : loading ? (
            <div className="flex items-center justify-center min-h-[400px]">
              <div className="text-center">
                <RefreshCw className="w-8 h-8 text-gray-400 animate-spin mx-auto mb-4" />
                <p className="text-gray-600">Loading admin data...</p>
              </div>
            </div>
          ) : (
            <>
              {/* Desktop Table View */}
              <div className="hidden md:block">
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
                          field="role"
                          currentSort={sortField}
                          direction={sortDirection}
                          onSort={handleSort}
                        >
                          ROLE
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
                        <TableHead className="w-20"></TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {admins.length > 0 ? (
                        admins.map((admin) => (
                          <TableRow key={admin.id} className="hover:bg-gray-50">
                            <TableCell className="font-medium">{admin.name}</TableCell>
                            <TableCell className="text-gray-600">{admin.email}</TableCell>
                            <TableCell className="text-gray-900">{admin.role}</TableCell>
                            <TableCell className="text-gray-600">{admin.joinDate}</TableCell>
                            <TableCell className="text-gray-600">{admin.lastLogin}</TableCell>
                            <TableCell>
                              <StatusBadge status={admin.status} />
                            </TableCell>
                            <TableCell>
                              <DeleteAdminModal
                                admin={admin}
                                onDelete={handleDeleteAdmin}
                                isLoading={deletingAdmins.has(admin.id)}
                              >
                                <Button
                                  variant="ghost"
                                  size="sm"
                                  className="text-red-600 hover:text-red-700 hover:bg-red-50"
                                  disabled={deletingAdmins.has(admin.id)}
                                >
                                  {deletingAdmins.has(admin.id) ? (
                                    <RefreshCw className="w-4 h-4 animate-spin" />
                                  ) : (
                                    <Trash2 className="w-4 h-4" />
                                  )}
                                </Button>
                              </DeleteAdminModal>
                            </TableCell>
                          </TableRow>
                        ))
                      ) : (
                        <TableRow>
                          <TableCell colSpan={7} className="text-center py-12">
                            <div className="flex flex-col items-center justify-center">
                              <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mb-4">
                                <svg className="w-8 h-8 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.25 2.25 0 11-4.5 0 2.25 2.25 0 014.5 0z" />
                                </svg>
                              </div>
                              <h3 className="text-lg font-semibold text-gray-900 mb-2">No Admins Found</h3>
                              <p className="text-gray-600 text-center mb-4">
                                There are no administrators to display.
                              </p>
                            </div>
                          </TableCell>
                        </TableRow>
                      )}
                    </TableBody>
                  </Table>
                </div>
              </div>

              {/* Mobile Cards View */}
              <div className="md:hidden space-y-4">
                {admins.length > 0 ? (
                  admins.map((admin) => (
                    <div key={admin.id} className="bg-white border border-gray-200 rounded-lg p-4 space-y-3">
                      <div className="flex items-start justify-between">
                        <div className="flex-1">
                          <h3 className="font-medium text-gray-900 text-base">{admin.name}</h3>
                          <p className="text-sm text-gray-600 mt-1">{admin.email}</p>
                        </div>
                        <div className="flex items-center space-x-2 ml-3">
                          <StatusBadge status={admin.status} />
                          <DeleteAdminModal
                            admin={admin}
                            onDelete={handleDeleteAdmin}
                            isLoading={deletingAdmins.has(admin.id)}
                          >
                            <Button
                              variant="ghost"
                              size="sm"
                              className="text-red-600 hover:text-red-700 hover:bg-red-50 p-2"
                              disabled={deletingAdmins.has(admin.id)}
                            >
                              {deletingAdmins.has(admin.id) ? (
                                <RefreshCw className="w-4 h-4 animate-spin" />
                              ) : (
                                <Trash2 className="w-4 h-4" />
                              )}
                            </Button>
                          </DeleteAdminModal>
                        </div>
                      </div>

                      <div className="grid grid-cols-2 gap-3 text-sm">
                        <div>
                          <span className="text-gray-500">Role:</span>
                          <span className="text-gray-900 ml-1">{admin.role}</span>
                        </div>
                        <div>
                          <span className="text-gray-500">Joined:</span>
                          <span className="text-gray-900 ml-1">{admin.joinDate}</span>
                        </div>
                        <div className="col-span-2">
                          <span className="text-gray-500">Last Login:</span>
                          <span className="text-gray-900 ml-1">{admin.lastLogin}</span>
                        </div>
                      </div>
                    </div>
                  ))
                ) : (
                  <div className="text-center py-12">
                    <div className="flex flex-col items-center justify-center">
                      <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mb-4">
                        <svg className="w-8 h-8 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.25 2.25 0 11-4.5 0 2.25 2.25 0 014.5 0z" />
                        </svg>
                      </div>
                      <h3 className="text-lg font-semibold text-gray-900 mb-2">No Admins Found</h3>
                      <p className="text-gray-600 text-center mb-4">
                        There are no administrators to display.
                      </p>
                    </div>
                  </div>
                )}
              </div>
            </>
          )}
        </CardContent>
      </Card>
    </div>
  )
}