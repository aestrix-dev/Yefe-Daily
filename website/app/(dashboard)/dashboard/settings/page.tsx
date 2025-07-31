'use client'
import React, { useState } from 'react'
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
import { ChevronUp, ChevronDown, Trash2, Plus } from 'lucide-react'
import type { Admin } from '@/lib/types'
import InviteAdminModal from '@/components/modals/InviteAdminModal'
import DeleteAdminModal from '@/components/modals/DeleteAdminModal'

// Mock data for admins
const mockAdmins: Admin[] = [
  {
    id: '1',
    name: 'Eleanor Pena',
    email: 'jessica.hanson@example.com',
    role: 'Admin',
    joinDate: 'Jan 24, 2020',
    lastLogin: 'Jan 24, 2020',
    status: 'Active'
  },
  {
    id: '2',
    name: 'Savannah Nguyen',
    email: 'alma.lawson@example.com',
    role: 'Admin',
    joinDate: 'Feb 1, 2020',
    lastLogin: 'Feb 1, 2020',
    status: 'Suspended'
  },
  {
    id: '3',
    name: 'Theresa Webb',
    email: 'kenzi.lawson@example.com',
    role: 'Admin',
    joinDate: 'Jan 19, 2020',
    lastLogin: 'Jan 19, 2020',
    status: 'Active'
  },
  {
    id: '4',
    name: 'Courtney Henry',
    email: 'michael.mitc@example.com',
    role: 'Admin',
    joinDate: 'Feb 1, 2020',
    lastLogin: 'Feb 1, 2020',
    status: 'Active'
  },
  {
    id: '5',
    name: 'Jerome Bell',
    email: 'deanna.curtis@example.com',
    role: 'Admin',
    joinDate: 'Feb 1, 2020',
    lastLogin: 'Feb 1, 2020',
    status: 'Active'
  },
  {
    id: '6',
    name: 'Ralph Edwards',
    email: 'debra.holt@example.com',
    role: 'Admin',
    joinDate: 'Feb 1, 2020',
    lastLogin: 'Feb 1, 2020',
    status: 'Active'
  }
]

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
  const [admins, setAdmins] = useState<Admin[]>(mockAdmins)
  const [sortField, setSortField] = useState<SortField | null>(null)
  const [sortDirection, setSortDirection] = useState<SortDirection>('asc')

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

  const handleInviteAdmin = (adminData: {  email: string; role: string }): void => {
    const newAdmin: Admin = {
      id: Date.now().toString(),
    //   name: adminData.name,
      email: adminData.email,
      role: adminData.role as 'Admin' ,
      joinDate: new Date().toLocaleDateString('en-US', { 
        year: 'numeric', 
        month: 'short', 
        day: 'numeric' 
      }),
      lastLogin: 'Never',
      status: 'Active'
    }

    setAdmins(prev => [...prev, newAdmin])
  }

  const handleDeleteAdmin = (adminId: string): void => {
    setAdmins(prev => prev.filter(admin => admin.id !== adminId))
  }

  return (
    <div className="p-6 space-y-6 bg-gray-50 min-h-screen">
      {/* Header */}
      <div className="flex items-center justify-between mt-10">
        <div>
          <h1 className="text-2xl font-semibold text-gray-900">Admin Role Management</h1>
          <p className="text-gray-600 mt-1">Manage administrator access and permissions</p>
        </div>
        <InviteAdminModal onInvite={handleInviteAdmin}>
          <Button className="bg-[#374035] hover:bg-[#2d332b] text-white">
            <Plus className="w-4 h-4 mr-2" />
            Invite New Admin
          </Button>
        </InviteAdminModal>
      </div>

      {/* Admins Table */}
      <Card className="shadow-none">
        <CardContent className="p-4">
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
              {admins.map((admin) => (
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
                    <DeleteAdminModal admin={admin} onDelete={handleDeleteAdmin}>
                      <Button variant="ghost" size="sm" className="text-red-600 hover:text-red-700 hover:bg-red-50">
                        <Trash2 className="w-4 h-4" />
                      </Button>
                    </DeleteAdminModal>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  )
}