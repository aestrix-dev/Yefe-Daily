import Footer from "@/components/Footer";
import Navbar from "@/components/Navbar";
import About from "@/components/sections/About";
import FAQ from "@/components/sections/FAQ";
import Hero from "@/components/sections/Hero";
import Journey from "@/components/sections/Journey";

export default function Home() {
  return (
    <>
      <Navbar />
      <Hero />
      <About />
      <Journey />
      <FAQ />
      <Footer />
    </>
  );
}
