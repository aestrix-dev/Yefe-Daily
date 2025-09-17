import React from 'react'
import Image from 'next/image'
import Link from 'next/link'

const About = () => {
  const features = [
    {
      id: 1,
      image: '/images/book-1.png',
      title: 'The Yefa Book',
      description: 'A written guide to becoming the best version of yourself',
      buttonText: 'Buy Now',
          buttonVariant: 'primary',
      link: '#'
    },
    {
      id: 2,
      image: '/images/book-2.png',
      title: 'Yefa Audiobook',
      description: 'Listen and grow on the go.',
      buttonText: 'Get Audiobook',
        buttonVariant: 'secondary',
      link: "https://yefalifestylemencave.com"
    },
    {
      id: 3,
      image: '/images/book-3.png',
      title: 'Yefa Fashion Line',
      description: 'Wear your values with pride',
      buttonText: 'Explore Fashion',
        buttonVariant: 'tertiary',
      link: "https://yefaclothing.com/"
    }
  ]

  return (
    <section id="about" className="py-20 lg:py-32 bg-[#374035] relative overflow-hidden">
      {/* Background decorative elements */}
      <div className="absolute inset-0 opacity-10">
        <div className="absolute top-10 left-10 w-32 h-32 bg-white rounded-full blur-3xl"></div>
        <div className="absolute bottom-20 right-20 w-48 h-48 bg-white rounded-full blur-3xl"></div>
        <div className="absolute top-1/2 left-1/4 w-24 h-24 bg-white rounded-full blur-2xl"></div>
          </div>
          
          

      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
        {/* Header Section */}
        <div className="mb-16 lg:mb-20">
          <h2 
            className="text-3xl text-center lg:text-start sm:text-4xl lg:text-5xl font-bold text-white mb-6"
            data-aos="fade-up"
            data-aos-duration="800"
            data-aos-delay="100"
          >
            About Yefa
          </h2>
          
          <p 
            className="font-lato text-center lg:text-start text-lg text-gray-200 leading-relaxed max-w-4xl"
            data-aos="fade-up"
            data-aos-duration="800"
            data-aos-delay="200"
          >
            Yefa is more than an app — it's a movement. Built for the modern African man, it combines 
            journaling, spiritual growth, daily challenges, music, and community to help you live intentionally 
            every day
          </p>
        </div>

        {/* Features Grid */}
        <div className="grid md:grid-cols-3 gap-8 lg:p-0 p-4 lg:gap-12">
          {features.map((feature, index) => (
            <div
              key={feature.id}
              className="bg-white/10 backdrop-blur-sm rounded-2xl p-6 border border-white/20 h-full flex flex-col group hover:bg-white/15 transition-all duration-300"
              data-aos="fade-up"
              data-aos-duration="800"
              data-aos-delay={300 + (index * 150)}
            >
              {/* Image Container */}
              <div className="relative mb-6 overflow-hidden rounded-xl bg-gradient-to-br from-gray-100 to-gray-200 aspect-square group-hover:scale-[1.02] transition-transform duration-500">
                <Image
                  src={feature.image}
                  alt={feature.title}
                  width={300}
                  height={300}
                  className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-700 rounded-xl"
                />
                
                {/* Overlay gradient on hover */}
                <div className="absolute inset-0 bg-black/0 group-hover:bg-black/20 transition-all duration-500 rounded-xl"></div>
              </div>

              {/* Content - flex-grow pushes button to bottom */}
              <div className="text-center flex-grow flex flex-col">
                <h3 className="font-playfair text-xl sm:text-2xl font-bold text-white mb-3 group-hover:text-gray-100 transition-colors duration-300">
                  {feature.title}
                </h3>
                
                <p className="font-lato text-gray-300 text-base sm:text-lg leading-relaxed mb-6 group-hover:text-gray-200 transition-colors duration-300 flex-grow">
                  {feature.description}
                </p>

                {/* Custom Button - pushed to bottom with mt-auto */}
                      <a
                  href={feature.link}
                  target='_blank'
                  className={`
                    w-full font-lato font-semibold px-6 py-3 rounded-full text-base transition-all duration-300 hover:scale-105 hover:shadow-lg mt-auto
                    ${feature.buttonVariant === 'primary' 
                      ? 'bg-white text-[#374035] hover:bg-gray-100' 
                      : feature.buttonVariant === 'secondary'
                      ? 'bg-gray-200 text-[#374035] hover:bg-white'
                      : 'bg-gray-300 text-[#374035] hover:bg-white'
                    }
                  `}
                >
                  {feature.buttonText}
                </a>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}

export default About
