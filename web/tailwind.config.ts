import type { Config } from 'tailwindcss'

export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        primary: '#e35203',
        'primary-hover': '#c84902',
        base: '#0d0d0f',
        panel: '#1a1a1d',
        border: '#2a2a2e',
        muted: '#8a8a90',
      },
    },
  },
  plugins: [],
} satisfies Config
