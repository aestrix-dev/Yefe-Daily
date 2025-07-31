
import React, { useState, useCallback } from 'react'
import { AxiosError } from 'axios'

interface ApiState<T> {
  data: T | null
  loading: boolean
  error: string | null
}

interface UseApiReturn<T> {
  data: T | null
  loading: boolean
  error: string | null
  execute: (...args: any[]) => Promise<T | null>
  reset: () => void
}

export function useApi<T = any>(
  apiFunction: (...args: any[]) => Promise<T>
): UseApiReturn<T> {
  const [state, setState] = useState<ApiState<T>>({
    data: null,
    loading: false,
    error: null,
  })

  const execute = useCallback(
    async (...args: any[]): Promise<T | null> => {
      try {
        setState(prev => ({ ...prev, loading: true, error: null }))
        
        const result = await apiFunction(...args)
        
        setState({
          data: result,
          loading: false,
          error: null,
        })
        
        return result
      } catch (error) {
        const errorMessage = getErrorMessage(error)
        
        setState({
          data: null,
          loading: false,
          error: errorMessage,
        })
        
        return null
      }
    },
    [apiFunction]
  )

  const reset = useCallback(() => {
    setState({
      data: null,
      loading: false,
      error: null,
    })
  }, [])

  return {
    data: state.data,
    loading: state.loading,
    error: state.error,
    execute,
    reset,
  }
}

// Helper function to extract error messages
function getErrorMessage(error: unknown): string {
  if (error instanceof AxiosError) {
    // Handle Axios errors
    if (error.response?.data?.message) {
      return error.response.data.message
    }
    if (error.response?.data?.error) {
      return error.response.data.error
    }
    if (error.message) {
      return error.message
    }
    return `HTTP Error: ${error.response?.status || 'Unknown'}`
  }
  
  if (error instanceof Error) {
    return error.message
  }
  
  return 'An unexpected error occurred'
}

// Hook for API calls that should execute immediately
export function useApiImmediate<T = any>(
  apiFunction: (...args: any[]) => Promise<T>,
  dependencies: any[] = []
): UseApiReturn<T> {
  const api = useApi(apiFunction)

  React.useEffect(() => {
    api.execute()
  }, dependencies)

  return api
}

// Hook for mutations (POST, PUT, DELETE operations)
export function useMutation<T = any, P = any>(
  apiFunction: (params: P) => Promise<T>
) {
  const [state, setState] = useState<ApiState<T>>({
    data: null,
    loading: false,
    error: null,
  })

  const mutate = useCallback(
    async (params: P): Promise<T | null> => {
      try {
        setState(prev => ({ ...prev, loading: true, error: null }))
        
        const result = await apiFunction(params)
        
        setState({
          data: result,
          loading: false,
          error: null,
        })
        
        return result
      } catch (error) {
        const errorMessage = getErrorMessage(error)
        
        setState({
          data: null,
          loading: false,
          error: errorMessage,
        })
        
        throw error 
      }
    },
    [apiFunction]
  )

  const reset = useCallback(() => {
    setState({
      data: null,
      loading: false,
      error: null,
    })
  }, [])

  return {
    data: state.data,
    loading: state.loading,
    error: state.error,
    mutate,
    reset,
  }
}