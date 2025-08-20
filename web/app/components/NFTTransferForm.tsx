import React, { useState } from 'react';
import { useReadContract } from 'wagmi'; 
import { abi } from "../abi";

interface NFTTransferFormProps {
  onTransfer: (from: string, to: string, tokenId: string) => Promise<void>;
}

export function NFTTransferForm({onTransfer}:NFTTransferFormProps) {
  const [from, setFrom] = useState('');
  const [to, setTo] = useState('');
  const [tokenId, setTokenId] = useState('');
  const [currentOwner, setCurrentOwner] = useState('');

  const contrct_add = "0xDf8d73Aa213f07285A40a7631F8369c67FF65ea9";

  const { 
    data: ownerData, 
    isError, 
    isLoading, 
    refetch
  } = useReadContract({
    abi,
    address: contrct_add,
    functionName: 'ownerOf',
    args: [BigInt(tokenId)],
  });

  const handleCheckOwner = () => {
    console.log('Checking owner for token ID:', tokenId);
    console.log('Contract address:', "0x285B1F4AEE4695AcE58307f4bdbaD41417661e50");
    console.log('Current owner:', currentOwner);
    refetch().then(() => {
      if (ownerData) {
        setCurrentOwner(ownerData);
        setFrom(ownerData);
      }
    });
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await onTransfer(from, to, tokenId);
      setTo('');
      setTokenId('');
      setCurrentOwner('');
    } catch (error) {
      console.error('NFT transfer failed:', error);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="bg-white/20 backdrop-blur-sm p-6 rounded-lg shadow-md">
      <div className="flex items-center gap-3 mb-6">
        <h2 className="text-xl font-bold text-white">NFT Transfer</h2>
      </div>

      <div className="mb-4">
        <label className="block text-sm font-medium mb-2 text-white">Token ID</label>
        <div className="flex gap-2">
          <input
            type="text"
            value={tokenId}
            onChange={(e) => setTokenId(e.target.value)}
            className="flex-1 p-2 border border-white/20 rounded-md text-white bg-white/10 placeholder-white/50"
            placeholder="Enter NFT Token ID"
            required
          />
          <button
            type="button"
            onClick={handleCheckOwner}
            className="px-4 py-2 bg-yellow-500 text-white rounded-md hover:bg-yellow-600 transition-colors"
          >
            Check Owner
          </button>
        </div>
      </div>

      {currentOwner && (
        <div className="mb-4 p-3 bg-white/10 rounded-md">
          <p className="text-sm text-white">Current Owner:</p>
          <p className="font-mono text-sm text-white">{currentOwner}</p>
        </div>
      )}

      {isLoading && <p className="text-white">Loading owner...</p>}
      {isError && <p className="text-red-400">Error fetching owner.</p>}

      <div className="mb-4">
        <label className="block text-sm font-medium mb-2 text-white">To Address</label>
        <input
          type="text"
          value={to}
          onChange={(e) => setTo(e.target.value)}
          className="w-full p-2 border border-white/20 rounded-md text-white bg-white/10 placeholder-white/50"
          placeholder="Recipient Address (0x...)"
          required
        />
      </div>

      <button
        type="submit"
        className="w-full bg-purple-500 text-white py-2 px-4 rounded-md hover:bg-purple-600 transition-colors"
      >
        Transfer NFT
      </button>
    </form>
  );
}