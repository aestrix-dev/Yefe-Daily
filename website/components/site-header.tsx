'use client'
import { Separator } from "@/components/ui/separator"
import { SidebarTrigger } from "@/components/ui/sidebar"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { usePathname } from "next/navigation"
import { useState, useEffect } from "react"
import { authService } from "@/services/auth.service"


const isObjectId = (id: string) => /^[a-f\d]{24}$/i.test(id)

function formatPathname(pathname: string) {
const segments = pathname.split("/").filter(Boolean)

const lastSegment = segments[segments.length - 1]
const previousSegment = segments[segments.length - 2]

if (isObjectId(lastSegment)) {
  return previousSegment
    .split("-")
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(" ")
}

return lastSegment
  .split("-")
  .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
  .join(" ")
}
export function SiteHeader() {
  const pathname = usePathname()
  const title = formatPathname(pathname)
  const [userData, setUserData] = useState({
    name: "Loading...",
    email: "",
    avatar: "/avatars/default.jpg",
  })

  useEffect(() => {
    // Try to get user data from localStorage first
    const storedUser = authService.getStoredUser()
    if (storedUser) {
      setUserData({
        name: storedUser.Name || storedUser.email,
        email: storedUser.email,
        avatar: storedUser.user_profile?.avatar_url || "/avatars/default.jpg",
      })
    } else {
      // If no stored user, try to fetch current user
      const fetchCurrentUser = async () => {
        try {
          const currentUser = await authService.getCurrentUser()
          setUserData({
            name: currentUser.Name || currentUser.email,
            email: currentUser.email,
            avatar: currentUser.user_profile?.avatar_url || "/avatars/default.jpg",
          })
        } catch (error) {
          console.error('Failed to fetch user data:', error)
          // Keep loading state if no user data available
        }
      }
      
      if (authService.isAuthenticated()) {
        fetchCurrentUser()
      }
    }
  }, [])
  return (
    <header className="flex py-3 h-(--header-height) shrink-0 items-center gap-2 border-b transition-[width,height] ease-linear group-has-data-[collapsible=icon]/sidebar-wrapper:h-(--header-height)">
      <div className="flex w-full items-center gap-1 px-4 lg:gap-2 lg:px-6">
        <SidebarTrigger className="-ml-1" />
        <Separator
          orientation="vertical"
          className="mx-2 data-[orientation=vertical]:h-4"
        />
        <h1 className="text-base font-medium">{ title }</h1>
        <div className="ml-auto flex items-center gap-2">
          <div className="flex items-center gap-3">
            <Avatar className="h-8 w-8 rounded-lg">
              <AvatarImage src={userData.avatar} alt={userData.name} />
              <AvatarFallback className="rounded-lg">
                {userData.name.charAt(0).toUpperCase()}
              </AvatarFallback>
            </Avatar>
            <div className="grid flex-1 text-left text-sm leading-tight">
              <span className="truncate font-medium">{userData.name}</span>
              <span className="text-muted-foreground truncate text-xs">
                {userData.email}
              </span>
            </div>
          </div>
        </div>
      </div>
    </header>
  )
}
