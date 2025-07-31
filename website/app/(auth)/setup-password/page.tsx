import { LoginForm } from "@/components/login-form"
import { SetPassword } from "@/components/set-password"

export default function Page() {
  return (
    <div className="relative flex min-h-svh w-full items-center justify-center p-6 md:p-10 bg-[#1E231D]">
      {/* Background image overlay */}
      <div 
        className="absolute inset-0 bg-cover bg-center bg-no-repeat opacity-[3%]"
        style={{ backgroundImage: 'url(/images/background.png)' }}
      />
      
      {/* Content */}
      <div className="relative z-10 w-full max-w-sm">
        <SetPassword />
      </div>
    </div>
  )
}