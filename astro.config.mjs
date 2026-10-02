// @ts-check
import { defineConfig } from 'astro/config';
import tailwindcss from '@tailwindcss/vite';
import sitemap from '@astrojs/sitemap';

export default defineConfig({
  site: 'https://autoleaf.nl',
  base: '/',
  integrations: [
    // /shows/ is an unlisted customer album; keep it out of the sitemap
    sitemap({ filter: (page) => !page.includes('/shows/') }),
  ],
  vite: {
    plugins: [tailwindcss()],
  },
});
