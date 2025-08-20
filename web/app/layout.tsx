// app/layout.tsx
import type { Metadata } from "next";
import { Providers } from "./providers/providers";
import "./globals.css";

export const metadata: Metadata = {
  title: "NFT Protocol",
  description: "ERC404 Implementation",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className="antialiased">
        <Providers>
          {children}
        </Providers>
      </body>
    </html>
  );
}