import { ActivityT } from '@/lib/types'
import React from 'react'


const ActivityItem = ({ activity }: { activity: ActivityT }) => {
  return (
    <div className="flex items-start justify-between py-3 border-b border-gray-100 last:border-0">
      <div className="flex-1">
        <div className="font-medium text-sm text-gray-900">{activity.type}</div>
        <div className="text-sm text-gray-500 mt-1">
          {activity.email || activity.description}
        </div>
      </div>
      <div className="text-xs text-gray-400 ml-4 whitespace-nowrap">
        {activity.time}
      </div>
    </div>
  )
}

export default ActivityItem