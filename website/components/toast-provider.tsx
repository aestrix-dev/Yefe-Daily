'use client'
import { Toaster } from 'react-hot-toast'

export function ToastProvider() {
  return (
    <Toaster
      position="top-right"
      reverseOrder={false}
      gutter={8}
      containerClassName=""
      containerStyle={{}}
      toastOptions={{
        // Default options for all toasts
        duration: 4000,
        style: {
          background: '#ffffff',
          color: '#374151',
          border: '1px solid #e5e7eb',
          borderRadius: '8px',
          boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)',
          fontSize: '14px',
          padding: '12px 16px',
        },
        // Success toast styling
        success: {
          style: {
            border: '1px solid #10b981',
            backgroundColor: '#f0fdf4',
            color: '#065f46',
          },
          iconTheme: {
            primary: '#10b981',
            secondary: '#f0fdf4',
          },
        },
        // Error toast styling
        error: {
          style: {
            border: '1px solid #ef4444',
            backgroundColor: '#fef2f2',
            color: '#991b1b',
          },
          iconTheme: {
            primary: '#ef4444',
            secondary: '#fef2f2',
          },
        },
        // Loading toast styling
        loading: {
          style: {
            border: '1px solid #6b7280',
            backgroundColor: '#f9fafb',
            color: '#374151',
          },
        },
      }}
    />
  )
}