import { AnalyticsChart } from '@/components/analytics';
import { StatCard } from '@/components/cards/StatCard';
import Challenge from '@/components/icons/Challenge';
import Daily from '@/components/icons/Daily';
import Premium from '@/components/icons/Premium';
import Users from '@/components/icons/Users';
import { Stat } from '@/lib/types';
import React from 'react'

const mockDashboardData: {
  stats: Stat[];
} = {
  stats: [
    {
      title: "Total Users",
      value: "15,260",
      change: "+3.5%",
      trend: "up",
      description: "from last month",
      icon: Users
    },
    {
      title: "Daily Active Users",
      value: "15,260",
      change: "+3.1%",
      trend: "up",
      description: "from last month",
      icon: Daily
    },
    {
      title: "Premium Subscribers",
      value: "15,260",
      change: "+30%",
      trend: "up",
      description: "from last month",
      icon: Premium
    },
    {
      title: "Avg. Session Time",
      value: "15,260",
      change: "+10%",
      trend: "up",
      description: "from last month",
      icon: Challenge
    }
  ]
}

const page = () => {
   return (
      <div className="p-6 space-y-6 bg-gray-50 min-h-screen">
        {/* Header */}
        <div>
          <h1 className="text-2xl font-semibold text-gray-900">Analytics & Reports</h1>
          <p className="text-gray-600 mt-1">Comprehensive insights into user behavior and content performance</p>
        </div>
  
        {/* Stats Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-4">
          {mockDashboardData.stats.map((stat, index) => (
            <StatCard key={index} stat={stat} />
          ))}
        </div>
  
           {/* Activity Section */}
           <AnalyticsChart />
       
      </div>
    )
}

export default page