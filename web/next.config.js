module.exports = {
  async rewrites() {
    return [
      {
        source: "/api/:path*", // 代理的本地路径
        destination: "https://sepolia.drpc.org/:path*", // 目标服务器
      },
    ];
  },
};