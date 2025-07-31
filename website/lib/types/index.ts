export type Stat = {
    title: string;
    value: string;
    change: string;
    trend: "up" | "down";
    description: string;
    icon: React.ElementType;
  };

  export type ActivityT = {
    type: string;
    email?: string;
    description?: string;
    time: string;
  };

  export type Insight = {
    title: string;
    value: string;
  };

  export interface Admin {
    id: string;
    name?: string;
    email: string;
    role: 'Admin' | 'Super Admin';
    joinDate: string;
    lastLogin: string;
    status: 'Active' | 'Suspended';
  }

  export interface User {
    id: string;
    name: string;
    email: string;
    plan: 'Free' | 'Yefa+';
    joinDate: string;
    lastLogin: string;
    status: 'Active' | 'Suspended' | 'Inactive';
    avatar?: string;
  }

  export interface UserManagementData {
    users: User[];
    totalUsers: number;
    activeUsers: number;
    suspendedUsers: number;
  }