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

import { X, Plus } from 'lucide-react'

interface InviteAdminModalProps {
  children: React.ReactNode;
  onInvite?: (adminData: { email: string; role: string }) => void;
}

const InviteAdminModal: React.FC<InviteAdminModalProps> = ({ children, onInvite }) => {
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    role: ''
  })
  const [isOpen, setIsOpen] = useState(false)

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    
    // Basic validation
    if (!formData.name || !formData.email || !formData.role) {
      return
    }

    // Call the onInvite callback if provided
    onInvite?.(formData)
    
    // Reset form and close modal
    setFormData({ name: '', email: '', role: '' })
    setIsOpen(false)
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
            <Label htmlFor="admin-name">Full Name</Label>
            <Input
              id="admin-email"
              type="email"
              placeholder="Enter full name"
              value={formData.name}
              onChange={(e) => handleInputChange('email', e.target.value)}
              required
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="admin-email">Assign Role</Label>
            <Input
              id="admin-email"
              type="text"
              placeholder="role (e.g. Admin)"
              value={formData.email}
              onChange={(e) => handleInputChange('role', e.target.value)}
              required
            />
          </div>

          {/* Action Buttons */}
          <div className="flex gap-3 pt-4">
            <Button 
              type="button" 
              variant="outline" 
              className="flex-1"
              onClick={() => setIsOpen(false)}
            >
              Cancel
            </Button>
            <Button 
              type="submit" 
              className="flex-1 bg-[#374035] hover:bg-[#2d332b] text-white"
            >
              Send Invitation
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  )
}

export default InviteAdminModal