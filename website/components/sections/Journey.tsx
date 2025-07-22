import Image from 'next/image'
import React from 'react'

const Journey = () => {
  return (
    <section className='py-20 flex flex-col items-center mx-auto max-w-6xl justify-center'>
      
      {/* Header Section */}
      <div className="mb-16 lg:mb-20">
        <h2 
          className="text-3xl text-center sm:text-4xl lg:text-5xl font-bold mb-6"
          data-aos="fade-up"
          data-aos-duration="800"
          data-aos-delay="100"
        >
          Ready To Start Your Yefa Journey
        </h2>
        
        <p 
          className="font-lato text-center text-lg text-gray-400 leading-relaxed max-w-4xl"
          data-aos="fade-up"
          data-aos-duration="800"
          data-aos-delay="200"
        >
          Enjoy your downloads on all platforms
        </p>
      </div>
      
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 w-full p-12">
        <div 
          className="flex items-center justify-center group"
          data-aos="fade-right"
          data-aos-duration="800"
          data-aos-delay="300"
        >
          <Image
            src={'/images/android.png'}
            alt={'android'}
            width={400}
            height={400}
            className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-700 rounded-xl"
          />
        </div>
        
        <div 
          className="flex items-center justify-center group"
          data-aos="fade-left"
          data-aos-duration="800"
          data-aos-delay="450"
        >
          <Image
            src={'/images/ios.png'}
            alt={'ios'}
            width={400}
            height={400}
            className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-700 rounded-xl"
          />
        </div>
      </div>
    </section>
  )
}

export default Journey
