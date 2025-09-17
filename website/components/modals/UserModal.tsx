
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
import { RefreshCw } from 'lucide-react'
import type { User } from '@/lib/types'

interface UserModalProps {
  user: User;
  children: React.ReactNode;
  onStatusToggle?: (userId: string, currentStatus: User['status']) => Promise<void>;
  isLoading?: boolean;
}

const UserModal: React.FC<UserModalProps> = ({ user, children, onStatusToggle, isLoading = false }) => {
  const isActive = user.status === 'Active'
  const [isOpen, setIsOpen] = useState(false)

  const handleStatusToggle = async () => {
    if (!onStatusToggle) return

    try {
      await onStatusToggle(user.id, user.status)
      setIsOpen(false) // Close modal on successful action
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
            <div>
              <DialogTitle className="text-xl font-semibold text-gray-900">
                User Details
              </DialogTitle>
              <DialogDescription className="text-gray-600 mt-1">
                View and manage user account information
              </DialogDescription>
            </div>
          
          </div>
        </DialogHeader>

        {/* Content */}
        <div className="px-6 pb-6 space-y-6">
          {/* User Info Section */}
          <div className="bg-[#F5F1EA] rounded-lg p-4 space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-500 mb-1">
                  Name
                </label>
                
              </div>
              <div className="text-right">
                <p className="text-sm text-gray-900">{user.name}</p>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-500 mb-1">
                  Email
                </label>
              </div>
              <div className="text-right">
                <p className="text-sm text-gray-900">{user.email}</p>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-500 mb-1">
                  Joined Date
                </label>
              </div>
              <div className="text-right">
                <p className="text-sm text-gray-900">{user.joinDate}</p>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-500 mb-1">
                  Last Login
                </label>
              </div>
              <div className="text-right">
                <p className="text-sm text-gray-900">{user.lastLogin}</p>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-500 mb-1">
                  Plan
                </label>
              </div>
              <div className="text-right">
                <p className="text-sm text-gray-900">{user.plan}</p>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-500 mb-1">
                  Status
                </label>
              </div>
              <div className="text-right">
                <p className="text-sm text-gray-900">{user.status}</p>
              </div>
            </div>
          </div>

          {/* Activity Section */}
          <div className="bg-[#F5F1EA] rounded-lg p-4 space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-500 mb-1">
                  Journal Entries
                </label>
              </div>
              <div className="text-right">
                <p className="text-sm text-gray-900">23</p>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-500 mb-1">
                  Current Streak
                </label>
              </div>
              <div className="text-right">
                <p className="text-sm text-gray-900">5 days</p>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-500 mb-1">
                  Challenges
                </label>
              </div>
              <div className="text-right">
                <p className="text-sm text-gray-900">{user.joinDate}</p>
              </div>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="flex gap-3 pt-4">
            <Button
              variant="outline"
              className="flex-1"
              onClick={() => setIsOpen(false)}
              disabled={isLoading}
            >
              Cancel
            </Button>
            <Button
              className={`flex-1 ${
                isActive
                  ? 'bg-red-500 hover:bg-red-600 text-white'
                  : 'bg-green-500 hover:bg-green-600 text-white'
              }`}
              onClick={handleStatusToggle}
              disabled={isLoading || !onStatusToggle}
            >
              {isLoading ? (
                <div className="flex items-center">
                  <RefreshCw className="w-4 h-4 mr-2 animate-spin" />
                  {isActive ? 'Suspending...' : 'Activating...'}
                </div>
              ) : (
                isActive ? 'Suspend User' : 'Activate User'
              )}
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}

export default UserModal