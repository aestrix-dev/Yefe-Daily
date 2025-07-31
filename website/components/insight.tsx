import { Insight } from '@/lib/types'
import React from 'react'

const InsightItem = ({ insight }: { insight: Insight }) => {
    return (
      <div className="flex items-center justify-between py-3 border-b border-gray-100 last:border-0">
        <div className="text-sm text-gray-700">{insight.title}</div>
        <div className="font-semibold text-gray-900">{insight.value}</div>
      </div>
    )
  }
  

export default InsightItem