import adminService from './admin.service'
import authService from './auth.service'
import dashboardService from './dashboard.service'
import userService from './user.service'


export { default as apiClient } from './config/api.config'


export const services = {
  auth: authService,
  user: userService,
  admin: adminService,
  dashboard: dashboardService,
}