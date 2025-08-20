"use client"
import Link from "next/link"
import { Github } from "lucide-react"
import { useState } from "react"
import { useRouter } from "next/navigation"

export default function Home() {
  const [language, setLanguage] = useState<"en" | "zh">("en") // 默认语言为英文
  const router = useRouter()

  const toggleLanguage = () => {
    setLanguage((prev) => (prev === "zh" ? "en" : "zh"))
  }

  const handleLearnMore = () => {
    console.log("Learn More button clicked")
    router.push("/main")
  }
  return (
    <main className="min-h-screen bg-gradient-to-r from-purple-400 via-pink-500 to-red-500 text-white">
      {/* Header - 固定在顶部 */}
      <header className="fixed top-0 left-0 right-0 bg-white/10 backdrop-blur-sm text-white p-6 flex items-center justify-between z-50 shadow-lg">
        <Link
          href="https://github.com/oftiyf/awesome_nft"
          className="flex items-center gap-2 hover:opacity-80 transition-opacity"
        >
          <Github size={40} />
          <span>GitHub</span>
        </Link>
        <button onClick={toggleLanguage} className="text-m hover:text-gray-300 transition-colors">
          {language === "zh" ? "English" : "中文"}
        </button>
      </header>

      {/* Hero Section */}
      <section className="h-screen flex flex-col items-center justify-center text-center px-4 pt-16">
        <div className="max-w-4xl mx-auto">
          <div className="mb-6"></div>
          <h1 className="text-5xl md:text-6xl font-bold mb-10">{language === "zh" ? "NFT 协议" : "NFT Protocol"}</h1>
          <p className="max-w-2xl text-lg md:text-xl mb-10 mx-auto">
            {language === "zh"
              ? "一种创新协议，将 NFT 与 FT 绑定，在增强流动性的同时保持 NFT 的奢侈属性"
              : "An innovative protocol that binds NFTs with fungible tokens (FT), enhancing liquidity while maintaining the luxury attributes of NFTs"}
          </p>
          <button
            type="button"
            onClick={handleLearnMore}
            className="bg-white/20 hover:bg-white/30 text-white font-medium py-3 px-8 rounded-full transition-all transform hover:scale-105 duration-300 backdrop-blur-sm shadow-lg"
          >
            {language === "zh" ? "了解更多" : "Learn More"}
          </button>
        </div>
      </section>

      {/* Core Values Section */}
      <section className="min-h-screen py-16 px-4 flex flex-col justify-center bg-white/10 backdrop-blur-sm">
        <div className="max-w-6xl mx-auto">
          <h2 className="text-4xl font-bold text-center mb-30 text-white">
            {language === "zh" ? "核心价值" : "Core Values"}
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-28">
            {/* Value Binding */}
            <div className="bg-white/20 backdrop-blur-sm p-6 rounded-lg hover:shadow-lg transition-all duration-300 hover:-translate-y-1 shadow-lg">
              <div className="mb-4">
                <h1 className="text-5xl mb-2">🔗</h1>
                <h3 className="text-2xl font-bold mb-2">{language === "zh" ? "价值绑定" : "Value Binding"}</h3>
              </div>
              <p className="text-white/90">
                {language === "zh"
                  ? "智能绑定 NFT 与 FT，实现价值互通"
                  : "Intelligently bind NFTs with FTs to achieve value interoperability"}
              </p>
            </div>

            {/* Enhanced Liquidity */}
            <div className="bg-white/20 backdrop-blur-sm p-6 rounded-lg hover:shadow-lg transition-all duration-300 hover:-translate-y-1 shadow-lg">
              <div className="mb-4">
                <h1 className="text-5xl mb-2">💧</h1>
                <h3 className="text-2xl font-bold mb-2">{language === "zh" ? "增强流动性" : "Enhanced Liquidity"}</h3>
              </div>
              <p className="text-white/90">
                {language === "zh"
                  ? "在保持 NFT 独特性的同时获得类似 FT 的流动性"
                  : "Gain FT-like liquidity while maintaining NFT uniqueness"}
              </p>
            </div>

            {/* Application Expansion */}
            <div className="bg-white/20 backdrop-blur-sm p-6 rounded-lg hover:shadow-lg transition-all duration-300 hover:-translate-y-1 shadow-lg">
              <div className="mb-4">
                <h1 className="text-5xl mb-2">🚀</h1>
                <h2 className="text-2xl font-bold ">{language === "zh" ? "应用扩展" : "Application Expansion"}</h2>
              </div>
              <p className="text-white/90">
                {language === "zh"
                  ? "支持多种资产形式，包括 LP 头寸、奢侈品 RWA 和游戏资产"
                  : "Support multiple asset forms including LP positions, luxury RWA, and gaming assets"}
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Use Cases Section - 全屏 */}
      <section className="min-h-screen py-16 px-4 bg-white/5 backdrop-blur-sm text-white flex flex-col justify-center">
        <div className="max-w-6xl mx-auto">
          <h2 className="text-4xl font-bold text-center mb-30">{language === "zh" ? "使用案例" : "Use Cases"}</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-18">
            {/* LP Position Optionization */}
            <div className="bg-black/30 backdrop-blur-sm p-6 rounded-lg hover:bg-black/40 transition-all duration-300 hover:shadow-xl shadow-lg">
              <div className="mb-4">
                <h1 className="text-5xl mb-2">💹</h1>
                <h3 className="text-2xl font-bold mb-2">
                  {language === "zh" ? "LP 头寸期权化" : "LP Position Optionization"}
                </h3>
              </div>
              <p className="text-white/80">
                {language === "zh"
                  ? "将 LP 头寸打包为 NFT，通过价值绑定机制实现类似期权的功能，为流动性提供者创造更多利润机会。"
                  : "Package LP positions as NFTs, achieving option-like functionality through value binding mechanism, creating more profit opportunities for liquidity providers."}
              </p>
            </div>

            {/* Luxury RWA */}
            <div className="bg-black/30 backdrop-blur-sm p-6 rounded-lg hover:bg-black/40 transition-all duration-300 hover:shadow-xl shadow-lg">
              <div className="mb-4">
                <h1 className="text-5xl mb-2">💎</h1>
                <h3 className="text-2xl font-bold mb-2">{language === "zh" ? "奢侈品 RWA" : "Luxury RWA"}</h3>
              </div>
              <p className="text-white/80">
                {language === "zh"
                  ? "通过 NFT 将现实世界的奢侈品资产代币化，通过价值绑定机制确保其真实价值，实现奢侈品资产的链上流通。"
                  : "Tokenize real-world luxury assets through NFTs, ensuring their true value through value binding mechanism, enabling on-chain circulation of luxury assets."}
              </p>
            </div>

            {/* GameFi Assets */}
            <div className="bg-black/30 backdrop-blur-sm p-6 rounded-lg hover:bg-black/40 transition-all duration-300 hover:shadow-xl shadow-lg">
              <div className="mb-4">
                <h1 className="text-5xl mb-2">🎮</h1>
                <h3 className="text-2xl font-bold mb-2">{language === "zh" ? "GameFi 资产" : "GameFi Assets"}</h3>
              </div>
              <p className="text-white/80">
                {language === "zh"
                  ? "稀有的游戏内物品和资产可以作为 NFT 存在，通过价值绑定机制实现跨游戏的价值互通和流动性。"
                  : "Rare in-game items and assets can exist as NFTs, achieving cross-game value interoperability and liquidity through value binding mechanism."}
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-black/40 backdrop-blur-sm text-white py-12 px-4">
        <div className="max-w-6xl mx-auto flex flex-col md:flex-row justify-between gap-8">
          {/* About */}
          <div className="flex-1">
            <h3 className="text-xl font-bold mb-4">{language === "zh" ? "NFT 协议" : "NFT Protocol"}</h3>
            <p className="text-white/80">
              {language === "zh"
                ? "一种创新协议，将 NFT 与 FT 绑定，在增强流动性的同时保持 NFT 的奢侈属性。"
                : "An innovative protocol that binds NFTs with fungible tokens (FT), enhancing liquidity while maintaining the luxury attributes of NFTs."}
            </p>
          </div>

          {/* Technical Features */}
          <div className="flex-1">
            <h3 className="text-xl font-bold mb-4">{language === "zh" ? "技术特点" : "Technical Features"}</h3>
            <ul className="text-white/80 space-y-2">
              <li className="hover:text-white transition-colors">
                {language === "zh" ? "智能绑定机制" : "Smart Binding Mechanism"}
              </li>
              <li className="hover:text-white transition-colors">
                {language === "zh" ? "价值保护" : "Value Protection"}
              </li>
              <li className="hover:text-white transition-colors">
                {language === "zh" ? "增强流动性" : "Enhanced Liquidity"}
              </li>
            </ul>
          </div>

          {/* Contact */}
          <div className="flex-1">
            <h3 className="text-xl font-bold mb-4">{language === "zh" ? "联系我们" : "Contact Us"}</h3>
            <p className="text-white/80 hover:text-white transition-colors">
              {language === "zh" ? "邮箱: oftiyf@gmail.com" : "Email: oftiyf@gmail.com"}
            </p>
          </div>
        </div>
        <div className="max-w-6xl mx-auto mt-8 pt-8 border-t border-white/20 text-center text-white/60">
          © 2025 NFT Protocol. {language === "zh" ? "版权所有。" : "All rights reserved."}
        </div>
      </footer>
    </main>
  )
}

