import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  base: '/admin/',
  server: {
    port: 5173,
    proxy: {
      '/admin/listings': {
        target: 'http://localhost:8000',
        changeOrigin: true,
      },
    },
  },
})
