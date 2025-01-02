// https://nuxt.com/docs/api/configuration/nuxt-config
import { resolve } from "path";

export default defineNuxtConfig({
  compatibilityDate: '2024-11-01',
  devtools: { enabled: true },
  future: { compatibilityVersion: 4 },

  /* START SECTION: RE-ENABLE Nuxt v3 behavior */
  srcDir: '.',

  dir: {
    app: 'app'
  },

  experimental: {
    scanPageMeta: 'after-resolve',
    sharedPrerenderData: false,
    compileTemplate: true,
    resetAsyncDataToUndefined: true,
    templateUtils: true,
    relativeWatchPaths: true,
    normalizeComponentNames: false,
    spaLoadingTemplateLocation: 'within',
    defaults: {
      useAsyncData: {
        deep: true
      }
    }
  },

  features: {
    inlineStyles: true
  },

  unhead: {
    renderSSRHeadOptions: {
      omitLineBreaks: false
    }
  },
  /* END SECTION: RE-ENABLE Nuxt v3 behavior */

  alias: {
    "@": resolve(__dirname, "/"),
  },

  app: {
    rootId: "hakarsa-custy",
    head: {
      meta: [
        {
          "charset": "utf-8"
        }
      ]
    }
  },

  css: [
    "~/assets/main.scss"
  ],

  modules: ["@nuxtjs/tailwindcss"],

  ssr: false,

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
