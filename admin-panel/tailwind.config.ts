import type { Config } from 'tailwindcss';

const config: Config = {
  content: ['./app/**/*.{js,ts,jsx,tsx,mdx}', './components/**/*.{js,ts,jsx,tsx,mdx}'],
  theme: {
    extend: {
      colors: {
        mf: {
          bg: '#0D0F1A',
          card: 'rgba(255, 255, 255, 0.04)',
          border: 'rgba(255, 255, 255, 0.1)',
          accent: '#8B7DFF',
          success: '#22C697',
          error: '#F07070',
          muted: '#8181A5',
        },
      },
      borderRadius: {
        '3xl': '24px',
        card: '24px',
      },
      backgroundImage: {
        'premium-gradient': 'linear-gradient(135deg, #0D0F1A 0%, #171B2D 100%)',
        'glass-gradient': 'linear-gradient(180deg, rgba(255, 255, 255, 0.08) 0%, rgba(255, 255, 255, 0.02) 100%)',
      },
      boxShadow: {
        'glass': '0 8px 32px 0 rgba(0, 0, 0, 0.37)',
        'neon-purple': '0 0 20px rgba(139, 125, 255, 0.3)',
      }
    },
  },
  plugins: [],
};

export default config;
