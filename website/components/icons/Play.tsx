import React from 'react'

interface PlayProps {
    className?: string;
}

const Play = ( {className} : PlayProps ) => {
  return (
      <div className={className}>
          <svg width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">
<circle cx="15.9993" cy="16" r="13.3333" stroke="#374035" stroke-width="1.5"/>
<path d="M20.5516 14.588C21.5939 15.2034 21.5939 16.7965 20.5516 17.4119L14.258 21.1277C13.2449 21.7258 12 20.9473 12 19.7157L12 12.2842C12 11.0526 13.2449 10.2741 14.258 10.8722L20.5516 14.588Z" stroke="#1C274C" stroke-width="1.5"/>
</svg>

    </div>
  )
}

export default Play