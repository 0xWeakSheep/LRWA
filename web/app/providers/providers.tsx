"use client";

import { getDefaultConfig, RainbowKitProvider} from "@rainbow-me/rainbowkit";
import { WagmiProvider } from "wagmi";
import { QueryClientProvider, QueryClient } from "@tanstack/react-query";
import { mainnet, sepolia } from 'wagmi/chains';

// 导入 RainbowKit 样式
import '@rainbow-me/rainbowkit/styles.css';

const config = getDefaultConfig({
    appName: "My RainbowKit App",
    projectId: "ERC404",
    chains: [mainnet, sepolia],
    ssr: true,
  });

const queryClient = new QueryClient();

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider
        >
          {children}
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}