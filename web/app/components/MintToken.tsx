import { useState } from "react";
import { Coins } from "lucide-react";

interface MintTokenProps {
  onMint: (amount: string) => Promise<void>;
}


export function MintToken({ onMint }: MintTokenProps) {
  const [amount, setAmount] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault(); // 阻止表单默认提交
    await onMint(amount); // 调用mint函数
  };
  
  return (
    <form onSubmit={handleSubmit}  className="bg-white/20 backdrop-blur-sm p-6 rounded-lg shadow-md">
      <div className="flex items-center gap-3 mb-6">
        <Coins className="w-5 h-5 text-white" />
        <h2 className="text-xl font-bold text-white">Mint Token</h2>
      </div>

      <p className="text-white/80 mb-4">Mint token to your account</p>

      <div className="flex flex-col gap-4">
        <div>
          <label className="block text-sm font-medium mb-2 text-white">Amount</label>
          <input
            type="text"
            placeholder="Input mint amount"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            className="w-full p-2 border border-white/20 rounded-md text-white bg-white/10 placeholder-white/50"
          />
        </div>
        <button 
         type="submit" 
          className="w-full bg-pink-500 text-white py-2 px-4 rounded-md hover:bg-pink-600 transition-colors"
        >
          Mint
        </button>
      </div>
    </form>
  );
}