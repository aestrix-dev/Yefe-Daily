import React from 'react'
import Image from 'next/image'
import Play from '../icons/Play'

const Hero = () => {
  return (
    <section id="home" className="relative lg:mt-28">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 pt-24 pb-32 lg:pb-0 ">
        <div className="grid lg:grid-cols-2 gap-12 lg:gap-16 items-end">
          
          {/* Left Content */}
          <div className="flex flex-col justify-end space-y-8  pb-28 lg:pb-16">
            
            {/* Heading */}
            <div className="space-y-6">
              <h1 
                className="font-playfair-display text-3xl lg:text-[40px] font-bold text-gray-900 leading-tight text-center lg:text-left mt-10 lg:mt-0"
                data-aos="fade-up"
                data-aos-duration="800"
                data-aos-delay="400"
              >
                Elevate Your Daily Life. Spiritually. Stylishly. Boldly
              </h1>
              
              <p 
                className="font-lato text-center lg:text-left text-base sm:text-lg text-gray-500 leading-relaxed max-w-2xl"
                data-aos="fade-up"
                data-aos-duration="800"
                data-aos-delay="600"
              >
                Built for the modern African man, it combines journaling, spiritual growth, daily challenges, music, and community to help you live intentionally every day.
              </p>
            </div>

            {/* Action Buttons */}
            <div 
              className="flex flex-col sm:flex-row gap-4 py-4 items-center lg:items-start sm:items-center"
              data-aos="fade-up"
              data-aos-duration="800"
              data-aos-delay="700"
            >
              <p 
                className="bg-[#374035] text-white font-lato font-semibold px-8 py-4 rounded-full text-lg transition-all duration-200 hover:scale-105 hover:shadow-lg cursor-pointer"
              >
                Download App
              </p>
              
              <button className="flex items-center space-x-2 text-gray-600 hover:text-green-600 transition-colors duration-200 group">
                <span className="font-lato font-medium text-base">How it works</span>
                <div className="w-12 h-12 bg-white rounded-full flex items-center justify-center shadow-md group-hover:shadow-lg transition-all duration-200 group-hover:scale-105">
                  <Play />
                </div>
              </button>
            </div>

            {/* Users Image */}
            <div 
              className="flex items-center justify-center lg:justify-start space-x-4"
              data-aos="fade-up"
              data-aos-duration="800"
              data-aos-delay="800"
            >
              <div className="relative">
                <Image
                  src="/images/users.png"
                  alt="Happy users"
                  width={120}
                  height={48}
                  className="w-auto h-12 object-contain"
                  priority
                />
              </div>
            </div>
          </div>

          {/* Right Content - iPhone */}
          <div className="flex justify-center lg:mb-[128px] lg:justify-end  relative">
            <div 
              className="relative"
              data-aos="fade-left"
              data-aos-duration="1000"
              data-aos-delay="900"
            >
              <Image
                src="/images/iphone.png"
                alt="Yefa App on iPhone"
                width={400}
                height={700}
                className="w-full max-w-[280px] sm:max-w-[320px] lg:max-w-[380px] xl:max-w-[420px] h-auto object-contain drop-shadow-2xl scale-200"
                priority
              />
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}

export default Hero