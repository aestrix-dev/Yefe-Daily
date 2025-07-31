'use client'
import { Separator } from "@/components/ui/separator"
import { SidebarTrigger } from "@/components/ui/sidebar"
import { NavUser } from "./nav-user"
import { usePathname } from "next/navigation"


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
  const data = {
    user: {
      name: "shadcn",
      email: "m@example.com",
      avatar: "/avatars/shadcn.jpg",
    }
  }
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
          <NavUser user={data.user} />
        </div>
      </div>
    </header>
  )
}
