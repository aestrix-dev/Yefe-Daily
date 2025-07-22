'use client'

import React, { useState } from 'react'
import { ChevronDown, ChevronUp } from 'lucide-react'

const FAQ = () => {
  const [activeIndex, setActiveIndex] = useState<number | null>(null)

  const faqs = [
    {
      id: 1,
      question: "What is Yefa and how does it work?",
      answer: "Yefa is a comprehensive lifestyle app designed for the modern African man. It combines journaling, spiritual growth, daily challenges, music, and community features to help you live intentionally every day. The app guides you through daily practices and connects you with like-minded individuals on similar journeys."
    },
    {
      id: 2,
      question: "Is Yefa free to use?",
      answer: "Yefa offers both free and premium features. You can download and use the basic features for free, including daily challenges and basic journaling. Premium features include advanced spiritual growth content, exclusive music playlists, and enhanced community access."
    },
    {
      id: 3,
      question: "How do the daily challenges work?",
      answer: "Daily challenges are personalized tasks designed to help you grow spiritually, physically, and mentally. Each day, you'll receive new challenges based on your progress and goals. You can track your completion and see your growth over time."
    },
    {
      id: 4,
      question: "Can I use Yefa offline?",
      answer: "Yes, many of Yefa's features work offline including journaling, viewing downloaded content, and accessing your personal growth materials. However, community features and live content require an internet connection."
    },
    {
      id: 5,
      question: "How do I join the Yefa community?",
      answer: "Once you download the app and create your profile, you'll automatically have access to the Yefa community. You can join discussion groups, participate in challenges with others, and connect with men who share similar values and goals."
    },
    {
      id: 6,
      question: "Is my personal data secure with Yefa?",
      answer: "Absolutely. We take your privacy seriously and use industry-standard encryption to protect your personal information. Your journal entries and personal data are stored securely and are never shared without your explicit consent."
    }
  ]

  const toggleFAQ = (index: number) => {
    setActiveIndex(activeIndex === index ? null : index)
  }

  return (
    <section id="faq" className="py-20 lg:py-32 bg-[#374035] relative overflow-hidden">
      {/* Background decorative elements */}
      <div className="absolute inset-0 opacity-10">
        <div className="absolute top-20 right-10 w-32 h-32 bg-white rounded-full blur-3xl"></div>
        <div className="absolute bottom-20 left-20 w-48 h-48 bg-white rounded-full blur-3xl"></div>
      </div>

      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
        <div className="grid lg:grid-cols-2 gap-12 lg:gap-16 items-start">
          
          {/* Left side - iPhone with background design */}
          <div className="order-2 lg:order-1 flex justify-center lg:justify-start">
            <div 
              className="relative"
              data-aos="fade-right"
              data-aos-duration="1000"
              data-aos-delay="200"
            >
              {/* Background circle design */}
              <div 
                className="absolute inset-0 -z-10"
                data-aos="zoom-in"
                data-aos-duration="1200"
                data-aos-delay="400"
              >
                <img
                  src="/images/faq-design.png"
                  alt="Background design"
                  className="w-[1020px] h-full object-contain opacity-80"
                />
              </div>
              
              {/* iPhone mockup */}
              <div className="relative z-10">
                <img
                  src="/images/faq-iphone.png"
                  alt="Yefa App FAQ Interface"
                  className="h-full w-[330px] object-contain drop-shadow-2xl"
                />
              </div>
            </div>
          </div>

          {/* Right side - FAQ Content */}
          <div className="order-1 lg:order-2">
            {/* Header */}
            <div className="mb-12">
              <h2 
                className="font-playfair text-3xl text-center lg:text-left  lg:text-4xl font-bold text-white mb-6"
                data-aos="fade-left"
                data-aos-duration="800"
                data-aos-delay="100"
              >
                Frequently Asked Questions
              </h2>
              
              <p 
                className="font-lato text-center lg:text-left text-lg text-gray-300 leading-relaxed"
                data-aos="fade-left"
                data-aos-duration="800"
                data-aos-delay="200"
              >
                Get answers to common questions about Yefa and how it can transform your daily routine.
              </p>
            </div>

            {/* FAQ Items */}
            <div className="space-y-4">
              {faqs.map((faq, index) => (
                <div
                  key={faq.id}
                  className="bg-white/10 backdrop-blur-sm rounded-xl border border-white/20 overflow-hidden transition-all duration-300 hover:bg-white/15"
                  data-aos="fade-left"
                  data-aos-duration="800"
                  data-aos-delay={300 + (index * 100)}
                >
                  <button
                    onClick={() => toggleFAQ(index)}
                    className="w-full px-6 py-5 text-left flex items-center justify-between focus:outline-none focus:ring-2 focus:ring-white/20"
                  >
                    <span className="font-lato font-semibold text-white text-base sm:text-lg pr-4">
                      {faq.question}
                    </span>
                    <div className="flex-shrink-0">
                      {activeIndex === index ? (
                        <ChevronUp className="w-5 h-5 text-white transition-transform duration-200" />
                      ) : (
                        <ChevronDown className="w-5 h-5 text-white transition-transform duration-200" />
                      )}
                    </div>
                  </button>
                  
                  <div 
                    className={`overflow-hidden transition-all duration-300 ease-in-out ${
                      activeIndex === index 
                        ? 'max-h-96 opacity-100' 
                        : 'max-h-0 opacity-0'
                    }`}
                  >
                    <div className="px-6 pb-5">
                      <p className="font-lato text-gray-300 leading-relaxed text-base">
                        {faq.answer}
                      </p>
                    </div>
                  </div>
                </div>
              ))}
            </div>

           
          </div>
        </div>
      </div>
    </section>
  )
}

export default FAQ