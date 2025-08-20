/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/**/*.{js,jsx,ts,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        'apple-gray': '#1d1d1f',
        'apple-light': '#f5f5f7',
        'apple-blue': '#0071e3',
      },
      fontFamily: {
        'sf-pro': ['SF Pro Display', 'sans-serif'],
      },
    },
  },
  plugins: [],
} 