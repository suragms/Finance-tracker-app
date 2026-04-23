import type { Config } from 'tailwindcss';

const config: Config = {
  content: ['./app/**/*.{js,ts,jsx,tsx,mdx}', './components/**/*.{js,ts,jsx,tsx,mdx}'],
  theme: {
    extend: {
      colors: {
        primary: '#4F46E5', // Indigo
        success: '#10B981', // Emerald
        error: '#F59E0B',   // Orange (Expense)
        background: '#F9FAFB',
        'mf-dark': '#111827',
        'mf-muted': '#6B7280',
        mf: {
          bg: '#F9FAFB',
          card: '#FFFFFF',
          border: '#E5E7EB',
          accent: '#4F46E5',
          success: '#10B981',
          error: '#F59E0B',
          muted: '#6B7280',
          purple: '#8B5CF6',
        },
      },
      fontFamily: {
        inter: ['var(--font-inter)', 'sans-serif'],
      },
      borderRadius: {
        '2xl': '16px',
        '3xl': '24px',
        card: '16px',
      },
      boxShadow: {
        'sm': '0 1px 2px 0 rgba(0, 0, 0, 0.05)',
        'glass': '0 8px 32px 0 rgba(0, 0, 0, 0.08)',
        'neon-purple': '0 0 20px rgba(79, 70, 229, 0.2)',
      }
    },
  },
  plugins: [
    require('tailwind-scrollbar-hide')
  ],
};

export default config;
