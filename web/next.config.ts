import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  eslint: {
    ignoreDuringBuilds: true, // 构建时完全忽略ESLint
  },
};

export default nextConfig;
