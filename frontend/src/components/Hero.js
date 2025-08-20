import React from 'react';
import { motion } from 'framer-motion';
import { useLanguage } from '../context/LanguageContext';

const Hero = () => {
  const { isChinese } = useLanguage();

  const content = {
    title: {
      en: "NFT Protocol",
      zh: "NFT Protocol"
    },
    description: {
      en: "An innovative protocol that binds NFTs with fungible tokens (FT), enhancing liquidity while maintaining the luxury attributes of NFTs",
      zh: "创新性的协议，通过将 NFT 与同质化代币(FT)进行价值绑定，在保持 NFT 奢侈品属性的同时增强其流动性"
    },
    button: {
      en: "Learn More",
      zh: "了解更多"
    }
  };

  return (
    <div className="relative h-screen flex items-center justify-center bg-apple-gray text-white">
      <div className="absolute inset-0 bg-gradient-to-b from-black/50 to-transparent" />
      <motion.div 
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.8 }}
        className="text-center z-10 px-4"
      >
        <h1 className="text-6xl font-bold mb-6">{content.title[isChinese ? 'zh' : 'en']}</h1>
        <p className="text-2xl mb-8 max-w-2xl mx-auto">
          {content.description[isChinese ? 'zh' : 'en']}
        </p>
        <motion.button
          whileHover={{ scale: 1.05 }}
          whileTap={{ scale: 0.95 }}
          className="bg-apple-blue text-white px-8 py-3 rounded-full text-lg font-medium"
        >
          {content.button[isChinese ? 'zh' : 'en']}
        </motion.button>
      </motion.div>
    </div>
  );
};

export default Hero; 