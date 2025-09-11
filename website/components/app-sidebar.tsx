"use client"

import * as React from "react"
import {
  IconChartBar,
  IconDashboard,
  IconUsers,
  IconSettings
} from "@tabler/icons-react"

import { NavMain } from "@/components/nav-main"
import { Button } from "@/components/ui/button"
import { IconLogout } from "@tabler/icons-react"
import { authService } from "@/services/auth.service"
import { useRouter } from "next/navigation"

import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuItem,
  SidebarMenuButton,
} from "@/components/ui/sidebar"
import Link from "next/link"

const data = {
  navMain: [
    {
      title: "Dashboard",
      url: "/dashboard",
      icon: IconDashboard,
    },
    {
      title: "Users Management",
      url: "/dashboard/user-management",
      icon: IconUsers,
    },
    {
      title: "Analytics & Reports",
      url: "/dashboard/analytics",
      icon: IconChartBar,
    },
    {
      title: "Settings",
      url: "/dashboard/settings",
      icon: IconSettings,
    }
  ],
}

export function AppSidebar({ ...props }: React.ComponentProps<typeof Sidebar>) {
  const router = useRouter()

  const handleLogout = async () => {
    try {
      await authService.logout()
      router.push('/sign-in') // Redirect to sign-in page after logout
    } catch (error) {
      console.error('Logout failed:', error)
    }
  }

  return (
    <Sidebar collapsible="offcanvas" {...props}>
      <SidebarHeader>
        <SidebarMenu>
          <SidebarMenuItem>
              <Link href="/" className="flex items-center my-3">
                <img src="/images/logo.png" alt="Logo" className="h-8 w-20" />
              </Link>
          </SidebarMenuItem>
        </SidebarMenu>
      </SidebarHeader>
      <SidebarContent>
        <NavMain items={data.navMain} />
      </SidebarContent>
      <SidebarFooter>
        <SidebarMenu>
          <SidebarMenuItem>
            <SidebarMenuButton onClick={handleLogout} className="w-full">
              <IconLogout className="mr-2 h-4 w-4" />
              <span>Log out</span>
            </SidebarMenuButton>
          </SidebarMenuItem>
        </SidebarMenu>
      </SidebarFooter>
    </Sidebar>
  )
}