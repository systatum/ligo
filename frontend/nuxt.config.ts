// https://nuxt.com/docs/api/configuration/nuxt-config
import { resolve } from "path";

export default defineNuxtConfig({
  compatibilityDate: '2024-11-01',
  devtools: { enabled: true },

  alias: {
    "@": resolve(__dirname, "/"),
  },

  css: [
    "~/assets/main.scss"
  ],

  modules: ["@nuxtjs/tailwindcss"],

  vite: {
    server: {
      // fix issue of docker not reflecting new (component) files
      watch: {
        usePolling: true,
        interval: 200,
      }
    }
  }
})
