'use client'

import React, { useState } from 'react'
import { Button } from '@/components/ui/button'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog'
import { X, Trash2, AlertTriangle, RefreshCw } from 'lucide-react'
import type { Admin } from '@/lib/types'

interface DeleteAdminModalProps {
  admin: Admin;
  children: React.ReactNode;
  onDelete?: (adminId: string) => Promise<void>;
  isLoading?: boolean;
}

const DeleteAdminModal: React.FC<DeleteAdminModalProps> = ({ admin, children, onDelete, isLoading = false }) => {
  const [isOpen, setIsOpen] = useState(false)

  const handleDelete = async () => {
    try {
      await onDelete?.(admin.id)
      setIsOpen(false)
    } catch (error) {
      // Error handling is done in parent component
    }
  }

  return (
    <Dialog open={isOpen} onOpenChange={setIsOpen}>
      <DialogTrigger asChild>
        {children}
      </DialogTrigger>
      <DialogContent className="max-w-md p-0 gap-0">
        {/* Header */}
        <DialogHeader className="p-6 pb-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <div className="flex items-center justify-center w-10 h-10 bg-red-100 rounded-full">
                <AlertTriangle className="w-5 h-5 text-red-600" />
              </div>
              <div>
                <DialogTitle className="text-xl font-semibold text-gray-900">
                  Delete Administrator
                </DialogTitle>
                <DialogDescription className="text-gray-600 mt-1">
                  This action cannot be undone
                </DialogDescription>
              </div>
            </div>
          
          </div>
        </DialogHeader>

        {/* Content */}
        <div className="px-6 pb-6">
          <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-6">
            <div className="space-y-2">
              <p className="text-sm text-gray-900">
                Are you sure you want to delete <span className="font-semibold">{admin.name}</span>?
              </p>
              <p className="text-sm text-gray-600">
                This will permanently remove their administrator access and cannot be undone. 
                They will lose all admin privileges immediately.
              </p>
            </div>
          </div>

          <div className="bg-gray-50 rounded-lg p-4 mb-6">
            <h4 className="font-medium text-gray-900 mb-2">Admin Details:</h4>
            <div className="space-y-1 text-sm">
              <p><span className="text-gray-500">Name:</span> {admin.name}</p>
              <p><span className="text-gray-500">Email:</span> {admin.email}</p>
              <p><span className="text-gray-500">Role:</span> {admin.role}</p>
              <p><span className="text-gray-500">Join Date:</span> {admin.joinDate}</p>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="flex gap-3">
            <Button
              variant="outline"
              className="flex-1"
              onClick={() => setIsOpen(false)}
              disabled={isLoading}
            >
              Cancel
            </Button>
            <Button
              variant="destructive"
              className="flex-1"
              onClick={handleDelete}
              disabled={isLoading}
            >
              {isLoading ? (
                <div className="flex items-center">
                  <RefreshCw className="w-4 h-4 mr-2 animate-spin" />
                  Deleting...
                </div>
              ) : (
                <div className="flex items-center">
                  <Trash2 className="w-4 h-4 mr-2" />
                  Delete Admin
                </div>
              )}
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}

export default DeleteAdminModal