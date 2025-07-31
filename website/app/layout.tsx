import type { Metadata } from "next";
import { Geist, Geist_Mono, Playfair_Display, Lato } from "next/font/google";
import "./globals.css";
import AOSProvider from "@/components/aos-provider";
import { ToastProvider } from "@/components/toast-provider";
import { AuthInitializer } from "@/components/auth-initializer";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

const playfairDisplay = Playfair_Display({
  variable: "--font-playfair-display",
  subsets: ["latin"],
  display: "swap",
});

const lato = Lato({
  variable: "--font-lato",
  subsets: ["latin"],
  weight: ["100", "300", "400", "700", "900"],
  display: "swap",
});

export const metadata: Metadata = {
  title: {
    default: "Yefa Daily - Elevate Your Life",
    template: "%s | Yefa" 
  },
  description: "Built for the modern African man. Combine journaling, spiritual growth, daily challenges, music, and community to live intentionally every day. Transform your routine into purposeful living.",
  keywords: [
    "African men lifestyle",
    "spiritual growth app",
    "daily journaling",
    "intentional living",
    "personal development",
    "mindfulness",
    "community building",
    "daily challenges",
    "spiritual wellness",
    "modern spirituality",
    "self-improvement",
    "African spirituality",
    "lifestyle transformation"
  ],
  authors: [{ name: "Frontend Engineer - Babawale Al-Ameen, Ui/Ux Designer - Ally Lawal" }], 
  creator: "Yefa",
  publisher: "Yefa",
  metadataBase: new URL("https://yefadaily.com"), 
  alternates: {
    canonical: "/",
  },
  openGraph: {
    type: "website",
    locale: "en_US",
    url: "https://yefadaily.com", 
    title: "Elevate Your Daily Life - Spiritually, Stylishly, Boldly",
    description: "Built for the modern African man. Combine journaling, spiritual growth, daily challenges, music, and community to live intentionally every day.",
    siteName: "Yefa", 
    images: [
      {
        url: "/og-image.jpg", 
        width: 1200,
        height: 630,
        alt: "Elevate Your Daily Life - Spiritual Growth App for African Men",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: "Yefa Daily - Elevate Your Life",
    description: "Built for the modern African man. Transform your routine into purposeful living with journaling, spiritual growth, and community.",
    images: ["/twitter-image.jpg"], 
    creator: "@yourtwitterhandle", 
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      "max-video-preview": -1,
      "max-image-preview": "large",
      "max-snippet": -1,
    },
  },
  verification: {
    google: "your-google-verification-code", 
  },
  category: "lifestyle",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <head>
        {/* Additional SEO elements */}
        <link rel="icon" href="/favicon.ico" />
        <link rel="apple-touch-icon" sizes="180x180" href="/apple-touch-icon.png" />
        <link rel="icon" type="image/png" sizes="32x32" href="/favicon-32x32.png" />
        <link rel="icon" type="image/png" sizes="16x16" href="/favicon-16x16.png" />
        {/* <link rel="manifest" href="/site.webmanifest" /> */}
        <meta name="theme-color" content="#000000" /> 
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        
        {/* Schema.org structured data */}
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{
            __html: JSON.stringify({
              "@context": "https://schema.org",
              "@type": "SoftwareApplication",
              "name": "Yefa Daily", 
              "description": "Built for the modern African man. Combine journaling, spiritual growth, daily challenges, music, and community to live intentionally every day.",
              "url": "https://yefadaily.com",
              "applicationCategory": "LifestyleApplication",
              "operatingSystem": "Web",
              "offers": {
                "@type": "Offer",
                "price": "5", 
                "priceCurrency": "USD"
              },
              "author": {
                "@type": "Organization",
                "name": "Super Team" 
              }
            })
          }}
        />
      </head>
      <body
        className={`${geistSans.variable} ${geistMono.variable} ${playfairDisplay.variable} ${lato.variable} antialiased font-lato`}
      >
        <AuthInitializer>
        <AOSProvider>
          {children}
        <ToastProvider />
        </AOSProvider>
        </AuthInitializer>
      </body>
    </html>
  );
}