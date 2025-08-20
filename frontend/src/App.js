import React from 'react';
import { motion } from 'framer-motion';
import { LanguageProvider } from './context/LanguageContext';
import Hero from './components/Hero';
import Features from './components/Features';
import UseCases from './components/UseCases';
import Footer from './components/Footer';
import LanguageToggle from './components/LanguageToggle';

function App() {
  return (
    <LanguageProvider>
      <div className="bg-apple-light min-h-screen font-sf-pro">
        <LanguageToggle />
        <Hero />
        <Features />
        <UseCases />
        <Footer />
      </div>
    </LanguageProvider>
  );
}

export default App; 