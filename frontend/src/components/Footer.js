import React from 'react';
import { useLanguage } from '../context/LanguageContext';

const Footer = () => {
  const { isChinese } = useLanguage();

  const content = {
    title: {
      en: "NFT Protocol",
      zh: "NFT Protocol"
    },
    description: {
      en: "An innovative protocol that binds NFTs with fungible tokens (FT), enhancing liquidity while maintaining the luxury attributes of NFTs.",
      zh: "创新性的协议，通过将 NFT 与同质化代币(FT)进行价值绑定，在保持 NFT 奢侈品属性的同时增强其流动性。"
    },
    features: {
      title: {
        en: "Technical Features",
        zh: "技术特点"
      },
      items: [
        {
          en: "Smart Binding Mechanism",
          zh: "智能绑定机制"
        },
        {
          en: "Value Protection",
          zh: "价值保护"
        },
        {
          en: "Enhanced Liquidity",
          zh: "流动性增强"
        }
      ]
    },
    contact: {
      title: {
        en: "Contact Us",
        zh: "联系我们"
      },
      email: {
        en: "Email: oftiyf@gmail.com",
        zh: "邮箱: oftiyf@gmail.com"
      }
    },
    copyright: {
      en: "© 2024 NFT Protocol. All rights reserved.",
      zh: "© 2024 NFT Protocol. 保留所有权利。"
    }
  };

  return (
    <footer className="bg-apple-gray text-white py-12">
      <div className="container mx-auto px-4">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          <div>
            <h3 className="text-xl font-semibold mb-4">{content.title[isChinese ? 'zh' : 'en']}</h3>
            <p className="text-gray-400">
              {content.description[isChinese ? 'zh' : 'en']}
            </p>
          </div>
          <div>
            <h3 className="text-xl font-semibold mb-4">{content.features.title[isChinese ? 'zh' : 'en']}</h3>
            <ul className="space-y-2 text-gray-400">
              {content.features.items.map((item, index) => (
                <li key={index}>{item[isChinese ? 'zh' : 'en']}</li>
              ))}
            </ul>
          </div>
          <div>
            <h3 className="text-xl font-semibold mb-4">{content.contact.title[isChinese ? 'zh' : 'en']}</h3>
            <p className="text-gray-400">
              {content.contact.email[isChinese ? 'zh' : 'en']}
            </p>
          </div>
        </div>
        <div className="border-t border-gray-800 mt-8 pt-8 text-center text-gray-400">
          <p>{content.copyright[isChinese ? 'zh' : 'en']}</p>
        </div>
      </div>
    </footer>
  );
};

export default Footer; 