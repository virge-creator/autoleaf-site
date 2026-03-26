// @ts-check
import { defineConfig } from 'astro/config';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  site: 'https://virge-creator.github.io',
  base: '/autoleaf-site',
  vite: {
    plugins: [tailwindcss()],
  },
});
