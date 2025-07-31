
import React from 'react'
import { Search } from 'lucide-react'

interface CustomSearchInputProps {
  placeholder?: string
  value: string
  onChange: (value: string) => void
  className?: string
  width?: string
}

const CustomSearchInput: React.FC<CustomSearchInputProps> = ({
  placeholder = "Search...",
  value,
  onChange,
  className = "",
  width = "320px"
}) => {
  return (
    <div 
      className={`relative ${className}`}
      style={{ width }}
    >
      <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
        <Search className="h-4 w-4 text-gray-400" />
      </div>
      <input
        type="text"
        placeholder={placeholder}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-md leading-5 bg-white placeholder-gray-500 focus:outline-none focus:placeholder-gray-400 focus:ring-1 focus:ring-gray-500 focus:border-gray-500 text-sm"
      />
    </div>
  )
}

export default CustomSearchInput