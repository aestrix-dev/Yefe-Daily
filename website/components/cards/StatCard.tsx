import { Stat } from "@/lib/types";
import { Card, CardContent, CardHeader, CardTitle } from "../ui/card";


  
 export const StatCard = ({ stat }: { stat: Stat }) => {
    const Icon = stat?.icon

    // Safely get values with fallbacks
    const title = stat?.title || 'Unknown'
    const value = stat?.value || '0'
    const change = stat?.change || '0.0%'
    const description = stat?.description || 'No data'
    const trend = stat?.trend || 'up'

    // Color coding based on trend
    const trendColors = trend === 'up'
      ? 'bg-green-100 text-green-700'
      : 'bg-red-100 text-red-700'

    return (
      <Card className='shadow-none'>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 ">
          <CardTitle className="text-lg font-medium text-gray-600">{title}</CardTitle>
          {Icon && <Icon className="h-4 w-4 text-gray-400 mr-5 mb-5" />}
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold text-gray-900">{value}</div>
          <div className="flex items-center space-x-2 text-xs mt-1">
            <span className="text-gray-500">{description}</span>
            <span className={`inline-flex items-center px-2 py-1 rounded-md ${trendColors}`}>
              {change}
            </span>
          </div>
        </CardContent>
      </Card>
    )
  }