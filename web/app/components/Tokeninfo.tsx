import React, { useState } from 'react';
import { CircleDollarSign, Coins, Wallet, Hash, Copy } from 'lucide-react';

interface TokenInfoProps {
  erc20Balance: string;
  erc721balance: string;
  symbol: string;
  totalSupply: string;
  nftIds?: string[]; // 接收 NFT ID 数组
}

export function TokenInfo({ 
  erc20Balance, 
  erc721balance, 
  symbol, 
  totalSupply, 
  nftIds = [] 
}: TokenInfoProps) {
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 8;
  const [copiedId, setCopiedId] = useState<string | null>(null);

  // 分页计算
  const totalPages = Math.ceil(nftIds.length / itemsPerPage);
  const paginatedNFTs = nftIds.slice(
    (currentPage - 1) * itemsPerPage,
    currentPage * itemsPerPage
  );

  // 复制 ID 到剪贴板
  const copyToClipboard = (id: string) => {
    navigator.clipboard.writeText(id);
    setCopiedId(id);
    setTimeout(() => setCopiedId(null), 2000);
  };

  // 短格式显示 ID
  const shortenId = (
    id: string | number | bigint,
    options?: {
      prefixLength?: number; // 开头保留长度（默认4）
      suffixLength?: number; // 结尾保留长度（默认4）
      separator?: string;    // 分隔符（默认"..."）
      showFullOnHover?: boolean; // 是否在hover时显示完整ID（需要配合CSS）
    }
  ) => {
    // 处理非字符串输入
    const strId = typeof id === 'string' ? id : id.toString();
    
    // 默认配置
    const {
      prefixLength = 4,
      suffixLength = 4,
      separator = '...',
      showFullOnHover = false
    } = options || {};
  
    // 边界情况处理
    if (strId.length <= prefixLength + suffixLength) {
      return strId;
    }
  
    // 生成缩短ID
    const prefix = strId.substring(0, prefixLength);
    const suffix = strId.substring(strId.length - suffixLength);
    
    return showFullOnHover 
      ? `<span class="short-id" title="${strId}">${prefix}${separator}${suffix}</span>`
      : `${prefix}${separator}${suffix}`;
  };

  return (
    <div className="space-y-8">
      {/* 代币信息卡片 */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Token Balance Card */}
        <div className="bg-white/20 backdrop-blur-sm p-4 rounded-lg shadow-md flex flex-col items-center text-center">
          <div className="flex items-center gap-2 mb-2">
            <Wallet className="w-5 h-5 text-white" />
            <h3 className="text-lg font-semibold text-white">Token Balance</h3>
          </div>
          <p className="text-xl font-bold text-white ">{erc20Balance} {symbol}</p>
        </div>

        {/* NFT Balance Card */}
        <div className="bg-white/20 backdrop-blur-sm p-4 rounded-lg shadow-md flex flex-col items-center text-center">
          <div className="flex items-center gap-2 mb-2">
            <Wallet className="w-5 h-5 text-white" />
            <h3 className="text-lg font-semibold text-white">NFT Balance</h3>
          </div>
          <p className="text-xl font-bold text-white">{erc721balance}</p>
        </div>

        {/* Total Supply Card */}
        <div className="bg-white/20 backdrop-blur-sm p-4 rounded-lg shadow-md flex flex-col items-center text-center">
          <div className="flex items-center gap-2 mb-2">
            <Coins className="w-5 h-5 text-white" />
            <h3 className="text-lg font-semibold text-white">Total Supply</h3>
          </div>
          <p className="text-xl font-bold text-white">{totalSupply} {symbol}</p>
        </div>

        {/* Token Symbol Card */}
        <div className="bg-white/20 backdrop-blur-sm p-4 rounded-lg shadow-md flex flex-col items-center text-center">
          <div className="flex items-center gap-2 mb-2">
            <CircleDollarSign className="w-5 h-5 text-white" />
            <h3 className="text-lg font-semibold text-white">Token Symbol</h3>
          </div>
          <p className="text-xl font-bold text-white">{symbol}</p>
        </div>
      </div>

      {/* NFT ID 列表展示 */}
      {nftIds.length > 0 && (
        <div className="bg-white/20 backdrop-blur-sm p-6 rounded-lg shadow-md">
          <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center mb-4 gap-4">
            <h3 className="text-xl font-bold flex items-center gap-2 text-white">
              <Hash className="w-5 h-5 text-white" />
              NFT IDs ({nftIds.length})
            </h3>
            <div className="text-sm bg-white/10 px-3 py-1 rounded text-white">
              Click any ID to copy
            </div>
          </div>
          
          <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3">
            {paginatedNFTs.map((id) => (
              <div 
                key={id} 
                className="border border-white/20 rounded-lg p-3 hover:bg-white/10 transition-colors cursor-pointer relative group"
                onClick={() => copyToClipboard(id)}
              >
                <div className="flex items-center gap-2">
                  <Hash className="w-4 h-4 text-white flex-shrink-0" />
                  {/* ID文本 - 确保垂直居中 */}
                  <span className="font-mono text-sm text-white leading-none self-center truncate max-w-[120px]">
                    {shortenId(id)}
                  </span>
                  <Copy className="w-3 h-3 text-white ml-auto opacity-0 group-hover:opacity-100 transition-opacity" />
                </div>
                {copiedId === id && (
                  <div className="absolute top-1 right-1 text-xs bg-white/20 text-white px-2 py-1 rounded">
                    Copied!
                  </div>
                )}
              </div>
            ))}
          </div>

          {/* 分页控制 */}
          {totalPages > 1 && (
            <div className="flex flex-col sm:flex-row justify-between items-center mt-6 gap-4">
              <div className="flex flex-wrap justify-center gap-2">
                
                <div className="flex items-center gap-1">
                  {Array.from({ length: Math.min(5, totalPages) }, (_, i) => {
                    let pageNum;
                    if (totalPages <= 5) {
                      pageNum = i + 1;
                    } else if (currentPage <= 3) {
                      pageNum = i + 1;
                    } else if (currentPage >= totalPages - 2) {
                      pageNum = totalPages - 4 + i;
                    } else {
                      pageNum = currentPage - 2 + i;
                    }
                    return (
                      <button
                        key={pageNum}
                        onClick={() => setCurrentPage(pageNum)}
                        className={`px-3 py-1 border border-white/20 rounded text-sm ${
                          currentPage === pageNum 
                            ? 'bg-white/20 text-white border-white/20' 
                            : 'hover:bg-white/10 text-white'
                        }`}
                      >
                        {pageNum}
                      </button>
                    );
                  })}
                  {totalPages > 5 && currentPage < totalPages - 2 && (
                    <span className="px-1 text-white">...</span>
                  )}
                  {totalPages > 5 && currentPage < totalPages - 2 && (
                    <button
                      onClick={() => setCurrentPage(totalPages)}
                      className="px-3 py-1 border border-white/20 rounded text-sm hover:bg-white/10 text-white"
                    >
                      {totalPages}
                    </button>
                  )}
                </div>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}