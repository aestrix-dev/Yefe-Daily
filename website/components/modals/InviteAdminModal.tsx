'use client'
import React, { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog'

import { X, Plus, RefreshCw } from 'lucide-react'

interface InviteAdminModalProps {
  children: React.ReactNode;
  onInvite?: (adminData: { email: string; role: string }) => Promise<void>;
  isLoading?: boolean;
}

const InviteAdminModal: React.FC<InviteAdminModalProps> = ({ children, onInvite, isLoading = false }) => {
  const [formData, setFormData] = useState({
    email: ''
  })
  const [isOpen, setIsOpen] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    // Basic validation
    if (!formData.email) {
      return
    }

    try {
      // Call the onInvite callback if provided
      await onInvite?.({ email: formData.email, role: 'Admin' })

      // Reset form and close modal on success
      setFormData({ email: '' })
      setIsOpen(false)
    } catch (error) {
      // Error handling is done in parent component
    }
  }

  const handleInputChange = (field: string, value: string) => {
    setFormData(prev => ({
      ...prev,
      [field]: value
    }))
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
                Invite New Admin
              </DialogTitle>
              <DialogDescription className="text-gray-600 mt-1">
                Send an invitation to add a new administrator
              </DialogDescription>
            </div>
          </div>
        </DialogHeader>

        {/* Content */}
        <form onSubmit={handleSubmit} className="px-6 pb-6 space-y-4">
          <div className="space-y-2">
            <Label htmlFor="admin-email">Email Address</Label>
            <Input
              id="admin-email"
              type="email"
              placeholder="Enter email address"
              value={formData.email}
              onChange={(e) => handleInputChange('email', e.target.value)}
              required
            />
          </div>

          <div className="bg-gray-50 border border-gray-200 rounded-lg p-4">
            <p className="text-sm text-gray-600">
              <strong>Note:</strong> An invitation email will be sent to this address.
              The new admin will be assigned the "Admin" role by default.
            </p>
          </div>

          {/* Action Buttons */}
          <div className="flex gap-3 pt-4">
            <Button
              type="button"
              variant="outline"
              className="flex-1"
              onClick={() => setIsOpen(false)}
              disabled={isLoading}
            >
              Cancel
            </Button>
            <Button
              type="submit"
              className="flex-1 bg-[#374035] hover:bg-[#2d332b] text-white"
              disabled={isLoading}
            >
              {isLoading ? (
                <div className="flex items-center">
                  <RefreshCw className="w-4 h-4 mr-2 animate-spin" />
                  Sending...
                </div>
              ) : (
                'Send Invitation'
              )}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  )
}

export default InviteAdminModal