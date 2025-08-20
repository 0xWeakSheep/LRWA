import React from 'react';
import { motion } from 'framer-motion';
import { useLanguage } from '../context/LanguageContext';

const Features = () => {
  const { isChinese } = useLanguage();

  const content = {
    title: {
      en: "Core Values",
      zh: "核心价值"
    },
    features: [
      {
        title: {
          en: "Value Binding",
          zh: "价值绑定"
        },
        description: {
          en: "Intelligently bind NFTs with FTs to achieve value interoperability",
          zh: "将 NFT 与 FT 进行智能绑定，实现价值互通"
        },
        icon: "🔗"
      },
      {
        title: {
          en: "Enhanced Liquidity",
          zh: "流动性增强"
        },
        description: {
          en: "Gain FT-like liquidity while maintaining NFT uniqueness",
          zh: "在保持 NFT 独特性的同时获得类似 FT 的流动性"
        },
        icon: "💧"
      },
      {
        title: {
          en: "Application Expansion",
          zh: "应用扩展"
        },
        description: {
          en: "Support multiple asset forms including LP positions, luxury RWA, and gaming assets",
          zh: "支持多种资产形态，包括 LP 头寸、奢侈品 RWA 和游戏资产"
        },
        icon: "🚀"
      }
    ]
  };

  return (
    <section className="py-20 bg-white">
      <div className="container mx-auto px-4">
        <motion.h2 
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8 }}
          className="text-4xl font-bold text-center mb-16"
        >
          {content.title[isChinese ? 'zh' : 'en']}
        </motion.h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {content.features.map((feature, index) => (
            <motion.div
              key={index}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.8, delay: index * 0.2 }}
              className="p-8 rounded-2xl bg-apple-light hover:shadow-lg transition-shadow"
            >
              <div className="text-4xl mb-4">{feature.icon}</div>
              <h3 className="text-2xl font-semibold mb-4">{feature.title[isChinese ? 'zh' : 'en']}</h3>
              <p className="text-gray-600">{feature.description[isChinese ? 'zh' : 'en']}</p>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
};

export default Features; 