import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// https://vite.dev/config/
export default defineConfig({
  plugins: [vue()],
  server: {
    host: '0.0.0.0',
    port: parseInt(process.env.PORT || '5173'),
    proxy: {
      '/api': {
        target: process.env.services__api__http__0 || process.env.services__api__https__0 || 'http://localhost:5063',
        changeOrigin: true,
        secure: false,
      },
    },
  },
})
