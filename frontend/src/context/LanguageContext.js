import React, { createContext, useState, useContext } from 'react';

const LanguageContext = createContext();

export const LanguageProvider = ({ children }) => {
  const [isChinese, setIsChinese] = useState(false);

  const toggleLanguage = () => {
    setIsChinese(!isChinese);
  };

  return (
    <LanguageContext.Provider value={{ isChinese, toggleLanguage }}>
      {children}
    </LanguageContext.Provider>
  );
};

export const useLanguage = () => useContext(LanguageContext); 