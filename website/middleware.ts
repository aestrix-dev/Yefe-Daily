// middleware.ts

import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl

  // Check if the request is for a protected route
  if (pathname.startsWith('/dashboard') || pathname.startsWith('/admin') || pathname.startsWith('/profile')) {
    const token = request.cookies.get('authToken')?.value
    const refreshToken = request.cookies.get('refreshToken')?.value

    
    if (!token) {
      const url = request.nextUrl.clone()
      url.pathname = '/'
      url.searchParams.set('redirectTo', pathname) 
      return NextResponse.redirect(url)
    }

    // Optional: Check token expiry if you store it in cookies
    const tokenExpiry = request.cookies.get('tokenExpiry')?.value
    if (tokenExpiry && Date.now() > parseInt(tokenExpiry)) {
     
      if (!refreshToken) {
        const url = request.nextUrl.clone()
        url.pathname = '/'
        url.searchParams.set('redirectTo', pathname)
        url.searchParams.set('reason', 'expired')
        return NextResponse.redirect(url)
      }
  
    }

    // Optional: Role-based access control
    if (pathname.startsWith('/admin')) {
      const userRole = request.cookies.get('userRole')?.value
      if (userRole !== 'admin') {
        const url = request.nextUrl.clone()
        url.pathname = '/dashboard' // Redirect non-admins to dashboard
        return NextResponse.redirect(url)
      }
    }
  }

  // Check if user is trying to access login page while already authenticated
  if (pathname === '/' || pathname === '/login') {
    const token = request.cookies.get('authToken')?.value
    if (token) {
      const url = request.nextUrl.clone()
      url.pathname = '/dashboard'
      return NextResponse.redirect(url)
    }
  }

  return NextResponse.next()
}

export const config = {
  matcher: [
    /*
     * Match all request paths except for the ones starting with:
     * - api (API routes)
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     */
    '/((?!api|_next/static|_next/image|favicon.ico|logo.png|images).*)',
  ],
}