import { reactRouter } from '@react-router/dev/vite';
import tailwindcss from '@tailwindcss/vite';
import { defineConfig } from 'vite';
import tsconfigPaths from 'vite-tsconfig-paths';
import devtoolsJson from 'vite-plugin-devtools-json';

export default defineConfig({
  plugins: [tailwindcss(), reactRouter(), tsconfigPaths(), devtoolsJson()],
  server: {
    host: true,
    port: 5173,
    allowedHosts: [
      'blog.bh-systems.be',         // Domaine de production
      'localhost',
      '127.0.0.1'
    ],
  },
});
