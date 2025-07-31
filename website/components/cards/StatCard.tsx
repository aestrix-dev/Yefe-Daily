import { Stat } from "@/lib/types";
import { Card, CardContent, CardHeader, CardTitle } from "../ui/card";


  
 export const StatCard = ({ stat }: { stat: Stat }) => {
    const Icon = stat.icon
    
    return (
      <Card className='shadow-none'>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 ">
          <CardTitle className="text-lg font-medium text-gray-600">{stat.title}</CardTitle>
          <Icon className="h-4 w-4 text-gray-400 mr-5 mb-5" />
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold text-gray-900">{stat.value}</div>
          <div className="flex items-center space-x-2 text-xs mt-1">
            <span className="text-gray-500">{stat.description}</span>
            <span className="inline-flex items-center px-2 py-1 rounded-md bg-green-100 text-green-700">
              {stat.change}
            </span>
          </div>
        </CardContent>
      </Card>
    )
  }