"use client"

import * as React from "react"
import {
  IconChartBar,
  IconDashboard,
  IconUsers,
  IconSettings
} from "@tabler/icons-react"

import { NavMain } from "@/components/nav-main"
import { NavUser } from "@/components/nav-user"

import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuItem,
} from "@/components/ui/sidebar"
import Link from "next/link"

const data = {
  user: {
    name: "shadcn",
    email: "m@example.com",
    avatar: "/avatars/shadcn.jpg",
  },
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
        <NavUser user={data.user} />
      </SidebarFooter>
    </Sidebar>
  )
}