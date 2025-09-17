'use client'
import * as React from "react"
import { useRouter, useSearchParams } from "next/navigation"
import toast from "react-hot-toast"
import { cn } from "@/lib/utils"
import { Button } from "@/components/ui/button"
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Eye, EyeOff, RefreshCw, CheckCircle } from "lucide-react"
import { adminService } from "@/services/admin.service"

export function SetPassword({
  className,
  ...props
}: React.ComponentProps<"div">) {
  const router = useRouter()
  const searchParams = useSearchParams()

  const [showPassword, setShowPassword] = React.useState(false)
  const [showConfirmPassword, setShowConfirmPassword] = React.useState(false)
  const [formData, setFormData] = React.useState({
    password: '',
    confirmPassword: ''
  })
  const [loading, setLoading] = React.useState(false)
  const [success, setSuccess] = React.useState(false)
  const [error, setError] = React.useState<string | null>(null)

  // Get token from URL
  const token = searchParams.get('token')

  // Check if token is present
  React.useEffect(() => {
    if (!token) {
      setError('Invalid invitation link. Token is missing.')
    }
  }, [token])

  const togglePasswordVisibility = () => {
    setShowPassword(!showPassword)
  }

  const toggleConfirmPasswordVisibility = () => {
    setShowConfirmPassword(!showConfirmPassword)
  }

  const handleInputChange = (field: string, value: string) => {
    setFormData(prev => ({
      ...prev,
      [field]: value
    }))
    // Clear error when user starts typing
    if (error) setError(null)
  }

  const validateForm = () => {
    if (!formData.password) {
      setError('Password is required')
      return false
    }
    if (formData.password.length < 8) {
      setError('Password must be at least 8 characters long')
      return false
    }
    if (!formData.confirmPassword) {
      setError('Please confirm your password')
      return false
    }
    if (formData.password !== formData.confirmPassword) {
      setError('Passwords do not match')
      return false
    }
    return true
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    if (!token) {
      setError('Invalid invitation link')
      return
    }

    if (!validateForm()) {
      return
    }

    try {
      setLoading(true)
      setError(null)

      await adminService.acceptInvitation(token, formData.password)

      setSuccess(true)
      toast.success('Password created successfully! Redirecting to login...', {
        duration: 3000,
        position: 'top-right',
      })

      // Redirect to login after 2 seconds
      setTimeout(() => {
        router.push('/sign-in')
      }, 2000)

    } catch (err: any) {
      const errorMessage = err?.response?.data?.message ||
                          err?.message ||
                          'Failed to create password. Please try again.'

      setError(errorMessage)
      toast.error(errorMessage, {
        duration: 4000,
        position: 'top-right',
      })
    } finally {
      setLoading(false)
    }
  }

  // Show success state
  if (success) {
    return (
      <div className={cn("flex flex-col gap-6", className)} {...props}>
        <Card>
          <div className="flex items-start justify-start">
            <img src="/logo.png" alt="Logo" className="h-16 w-12 ml-4" />
          </div>
          <CardHeader className="text-center">
            <div className="flex justify-center mb-4">
              <CheckCircle className="w-16 h-16 text-green-600" />
            </div>
            <CardTitle className="text-green-600">Password Created Successfully!</CardTitle>
            <CardDescription>
              Your admin account has been set up. You will be redirected to the login page shortly.
            </CardDescription>
          </CardHeader>
        </Card>
      </div>
    )
  }

  return (
    <div className={cn("flex flex-col gap-6", className)} {...props}>
      <Card>
        <div className="flex items-start justify-start">
          <img src="/logo.png" alt="Logo" className="h-16 w-12 ml-4" />
        </div>
        <CardHeader>
          <CardTitle>Setup Password</CardTitle>
          <CardDescription>
            To complete your admin account setup, please create a password for your account.
          </CardDescription>
        </CardHeader>
        <CardContent>
          {/* Error display */}
          {error && (
            <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg">
              <p className="text-sm text-red-600">{error}</p>
            </div>
          )}

          {/* Token missing state */}
          {!token ? (
            <div className="text-center py-6">
              <p className="text-red-600 mb-4">Invalid invitation link</p>
              <Button
                onClick={() => router.push('/sign-in')}
                variant="outline"
                className="w-full"
              >
                Go to Login
              </Button>
            </div>
          ) : (
            <form onSubmit={handleSubmit}>
              <div className="flex flex-col gap-6">
                <div className="grid gap-3">
                  <div className="flex items-center">
                    <Label htmlFor="password">Password</Label>
                  </div>
                  <Input
                    id="password"
                    type={showPassword ? "text" : "password"}
                    placeholder="Enter your password"
                    value={formData.password}
                    onChange={(e) => handleInputChange('password', e.target.value)}
                    disabled={loading}
                    required
                    icon={
                      <button
                        type="button"
                        onClick={togglePasswordVisibility}
                        className="hover:text-gray-700 transition-colors"
                        disabled={loading}
                      >
                        {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                      </button>
                    }
                  />
                  <p className="text-xs text-gray-500">Password must be at least 8 characters long</p>
                </div>
                <div className="grid gap-3">
                  <div className="flex items-center">
                    <Label htmlFor="confirmPassword">Confirm Password</Label>
                  </div>
                  <Input
                    id="confirmPassword"
                    type={showConfirmPassword ? "text" : "password"}
                    placeholder="Confirm your password"
                    value={formData.confirmPassword}
                    onChange={(e) => handleInputChange('confirmPassword', e.target.value)}
                    disabled={loading}
                    required
                    icon={
                      <button
                        type="button"
                        onClick={toggleConfirmPasswordVisibility}
                        className="hover:text-gray-700 transition-colors"
                        disabled={loading}
                      >
                        {showConfirmPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                      </button>
                    }
                  />
                </div>
                <div className="flex flex-col gap-3">
                  <Button type="submit" className="w-full" disabled={loading}>
                    {loading ? (
                      <div className="flex items-center">
                        <RefreshCw className="w-4 h-4 mr-2 animate-spin" />
                        Creating Password...
                      </div>
                    ) : (
                      'Create Password'
                    )}
                  </Button>
                </div>
              </div>
            </form>
          )}
        </CardContent>
      </Card>
    </div>
  )
}