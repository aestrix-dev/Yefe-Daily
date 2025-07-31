'use client'

import React, { useState, useEffect } from 'react'
import Link from 'next/link'
import Image from 'next/image'
import { Button } from '@/components/ui/button'
import { Sheet, SheetContent, SheetTrigger } from '@/components/ui/sheet'
import { Menu, Download } from 'lucide-react'
import { cn } from '@/lib/utils'

const Navbar = () => {
  const [isOpen, setIsOpen] = useState(false)

  // Optional: Update active section based on scroll position
  useEffect(() => {
    const handleScroll = () => {
      const sections = ['home', 'about', 'faq']
        const scrollPosition = window.scrollY + 100

      for (const section of sections) {
        const element = document.getElementById(section)
        if (element) {
          const { offsetTop, offsetHeight } = element
          if (scrollPosition >= offsetTop && scrollPosition < offsetTop + offsetHeight) {
            setActiveSection(`#${section}`)
            break
          }
        }
      }
    }

    window.addEventListener('scroll', handleScroll)
    return () => window.removeEventListener('scroll', handleScroll)
  }, [])

  const navItems = [
    { href: '#home', label: 'Home' },
    { href: '#about', label: 'About' },
    { href: '#faq', label: 'FAQ' },
  ]

  const [activeSection, setActiveSection] = useState('#home')

  // Handle smooth scroll to section
  const handleNavClick = (href: string, e: React.MouseEvent) => {
    e.preventDefault()
      const targetId = href.substring(1)
    const targetElement = document.getElementById(targetId)
    
    if (targetElement) {
      targetElement.scrollIntoView({
        behavior: 'smooth',
        block: 'start'
      })
      setActiveSection(href)
      setIsOpen(false) 
    }
  }

  const isActiveTab = (href: string) => {
    return activeSection === href
  }

  return (
    <nav className="fixed top-0 left-0 right-0 z-50 bg-white/80 backdrop-blur-md border-b border-white/20 animate-slide-down py-3">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 ">
        <div className="flex items-center justify-between h-12 lg:h-24">
          {/* Logo */}
          <Link href="/" className="flex items-center space-x-2">
            <div 
              className="flex items-center space-x-2"
              data-aos="fade-down"
              data-aos-duration="800"
              data-aos-delay="100"
            >
              <Image
                src="/logo.png"
                alt="Yefa Logo"
                width={40}
                height={40}
                className="lg:w-24 lg:h-24 h-16 w-16 object-contain"
                priority
              />
            </div>
          </Link>

          {/* Desktop Navigation */}
          <div className="hidden md:block">
            <div 
              className="bg-white rounded-full px-1 py-1 shadow-sm border border-gray-100"
              data-aos="fade-down"
              data-aos-duration="800"
              data-aos-delay="200"
            >
              <div className="flex items-center space-x-1">
                {navItems.map((item) => (
                  <a
                    key={item.href}
                    href={item.href}
                    onClick={(e) => handleNavClick(item.href, e)}
                    className={cn(
                      "px-4 py-2 rounded-full text-sm font-medium transition-all duration-200 cursor-pointer",
                      isActiveTab(item.href)
                        ? "bg-[#374035] text-white shadow-sm"
                        : "text-gray-600 hover:text-gray-900 hover:bg-gray-50"
                    )}
                  >
                    {item.label}
                  </a>
                ))}
              </div>
            </div>
          </div>

          {/* Desktop Download Button */}
          <div className="hidden md:block  p-4">
            <p 
              className="bg-[#374035] flex  text-white rounded-full px-8 py-3 text-lg"
              data-aos="fade-down"
              data-aos-duration="800"
              data-aos-delay="300"
            >
              {/* <Download className="w-4 h-4 mr-2" /> */}
              Download App
            </p>
          </div>

          {/* Mobile Menu Trigger */}
          <div className="md:hidden">
            <Sheet open={isOpen} onOpenChange={setIsOpen}>
              <SheetTrigger asChild>
                <Button variant="ghost" size="icon" className="text-gray-600">
                  <Menu className="w-6 h-6" />
                  <span className="sr-only">Open menu</span>
                </Button>
              </SheetTrigger>
              <SheetContent side="top" className="w-full">
                <div className="flex flex-col space-y-4 ">
                  {/* Logo in Mobile Menu */}
                  <Link 
                    href="/" 
                    className="flex items-center space-x-2 pb-4 border-b pt-2  border-gray-200"
                    onClick={() => setIsOpen(false)}
                  >
                    <Image
                      src="/logo.png"
                      alt="Yefa Logo"
                      width={32}
                      height={32}
                      className="w-12 h-12 object-contain"
                    />
                   
                  </Link>

                  {/* Mobile Navigation Links */}
                  <div className="flex flex-col space-y-2 px-12">
                    {navItems.map((item) => (
                      <Link
                        key={item.href}
                        href={item.href}
                        onClick={() => setIsOpen(false)}
                        className={cn(
                          "px-4 py-3 rounded-full text-base font-medium transition-all duration-200",
                          isActiveTab(item.href)
                            ? "bg-[#374035] text-white"
                            : "text-gray-600 hover:text-gray-900 hover:bg-gray-50"
                        )}
                      >
                        {item.label}
                      </Link>
                    ))}
                  </div>

                  {/* Mobile Download Button */}
                  <div className="py-4 px-12 flex items-center justify-center ">
                    <p className="w-full bg-[#374035]  text-white rounded-full py-3 text-center text-lg font-medium">
                      {/* <Download className="w-4 h-4 mr-2" /> */}
                      Download App
                    </p>
                  </div>
                </div>
              </SheetContent>
            </Sheet>
          </div>
        </div>
      </div>
    </nav>
  )
}

export default Navbar