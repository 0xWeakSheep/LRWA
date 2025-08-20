import React from 'react';
import { motion } from 'framer-motion';
import { useLanguage } from '../context/LanguageContext';

const UseCases = () => {
  const { isChinese } = useLanguage();

  const content = {
    title: {
      en: "Use Cases",
      zh: "应用场景"
    },
    useCases: [
      {
        title: {
          en: "LP Position Optionization",
          zh: "LP 头寸期权化"
        },
        description: {
          en: "Package LP positions as NFTs, achieving option-like functionality through value binding mechanism, creating more profit opportunities for liquidity providers.",
          zh: "将 LP 头寸包装成 NFT，通过价值绑定机制实现类似期权的功能，为流动性提供者创造更多收益机会。"
        },
        image: "📈"
      },
      {
        title: {
          en: "Luxury RWA",
          zh: "奢侈品 RWA"
        },
        description: {
          en: "Tokenize real-world luxury assets through NFTs, ensuring their true value through value binding mechanism, enabling on-chain circulation of luxury assets.",
          zh: "将现实世界中的奢侈品资产通过 NFT 进行代币化，并通过价值绑定机制确保其真实价值，实现奢侈品资产的链上流通。"
        },
        image: "💎"
      },
      {
        title: {
          en: "GameFi Assets",
          zh: "GameFi 资产"
        },
        description: {
          en: "Rare in-game items and assets can exist as NFTs, achieving cross-game value interoperability and liquidity through value binding mechanism.",
          zh: "游戏中的稀有道具和资产可以通过 NFT 形式存在，并通过价值绑定机制实现跨游戏的价值互通和流动性。"
        },
        image: "🎮"
      }
    ]
  };

  return (
    <section className="py-20 bg-apple-gray text-white">
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
          {content.useCases.map((useCase, index) => (
            <motion.div
              key={index}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.8, delay: index * 0.2 }}
              className="p-8 rounded-2xl bg-white/10 backdrop-blur-sm hover:bg-white/20 transition-colors"
            >
              <div className="text-6xl mb-6">{useCase.image}</div>
              <h3 className="text-2xl font-semibold mb-4">{useCase.title[isChinese ? 'zh' : 'en']}</h3>
              <p className="text-gray-300">{useCase.description[isChinese ? 'zh' : 'en']}</p>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
};

export default UseCases; 