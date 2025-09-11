
import axios, { AxiosInstance, AxiosRequestConfig, AxiosResponse, AxiosError } from 'axios'

// API Configuration
const API_CONFIG = {
  BASE_URL: process.env.NEXT_PUBLIC_API_URL,
  TIMEOUT: 10000,
}

// Create Axios instance
const apiClient: AxiosInstance = axios.create({
  baseURL: API_CONFIG.BASE_URL,
  timeout: API_CONFIG.TIMEOUT,
  headers: {
    'Content-Type': 'application/json',
  },
})

// Request interceptor
apiClient.interceptors.request.use(
  (config: import('axios').InternalAxiosRequestConfig) => {
    // Get token from localStorage or your preferred storage
    const token = typeof window !== 'undefined' ? localStorage.getItem('authToken') : null

    if (token) {
      if (config.headers) {
        config.headers['Authorization'] = `Bearer ${token}`;
      }
    }

    return config
  },
  (error: AxiosError) => {
    return Promise.reject(error)
  }
)

// Response interceptor
apiClient.interceptors.response.use(
  (response: AxiosResponse) => {
    return response
  },
  async (error: AxiosError) => {
    const originalRequest = error.config as AxiosRequestConfig & { _retry?: boolean }
    
    // Handle 401 errors (unauthorized)
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true
      
      // Clear token and redirect to sign-in
      if (typeof window !== 'undefined') {
        localStorage.removeItem('authToken')
        window.location.href = '/sign-in'
      }
    }
    
    return Promise.reject(error)
  }
)

// Base service class
export abstract class BaseService {
  protected client: AxiosInstance
  protected baseEndpoint: string

  constructor(baseEndpoint: string) {
    this.client = apiClient
    this.baseEndpoint = baseEndpoint
  }

  // Generic CRUD methods
  protected async get<T>(endpoint: string = ''): Promise<T> {
    const response = await this.client.get<T>(`${this.baseEndpoint}${endpoint}`)
    return response.data
  }

  protected async post<T, D = any>(data: D, endpoint: string = ''): Promise<T> {
    const response = await this.client.post<T>(`${this.baseEndpoint}${endpoint}`, data)
    return response.data
  }

  protected async put<T, D = any>(data: D, endpoint: string = ''): Promise<T> {
    const response = await this.client.put<T>(`${this.baseEndpoint}${endpoint}`, data)
    return response.data
  }

  protected async patch<T, D = any>(data: D, endpoint: string = ''): Promise<T> {
    const response = await this.client.patch<T>(`${this.baseEndpoint}${endpoint}`, data)
    return response.data
  }

  protected async delete<T>(endpoint: string = ''): Promise<T> {
    const response = await this.client.delete<T>(`${this.baseEndpoint}${endpoint}`)
    return response.data
  }
}

export default apiClient