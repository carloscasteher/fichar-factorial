import { defineConfig } from "vitepress";

const repo = "https://github.com/carloscasteher/fichar-factorial";

export default defineConfig({
  lang: "es-ES",
  title: "fichar-factorial",
  description: "Ficha en Factorial desde tu agente de IA, con horario fijo o aleatorio dentro de una franja.",
  base: "/fichar-factorial/",
  cleanUrls: true,
  lastUpdated: true,
  themeConfig: {
    nav: [
      { text: "Guía", link: "/instalacion" },
      { text: "Comandos", link: "/comandos" },
    ],
    sidebar: [
      {
        text: "Guía",
        items: [
          { text: "Instalación", link: "/instalacion" },
          { text: "Uso", link: "/uso" },
          { text: "A tener en cuenta", link: "/a-tener-en-cuenta" },
        ],
      },
      {
        text: "Referencia",
        items: [
          { text: "Comandos", link: "/comandos" },
          { text: "Seguridad", link: "/seguridad" },
        ],
      },
    ],
    socialLinks: [{ icon: "github", link: repo }],
    editLink: {
      pattern: `${repo}/edit/main/docs/:path`,
      text: "Editar esta página en GitHub",
    },
    footer: {
      message: "Dominio público (The Unlicense). Usa factorial-cli de Daniel Ramos Acosta.",
    },
    search: {
      provider: "local",
      options: {
        translations: {
          button: { buttonText: "Buscar", buttonAriaLabel: "Buscar" },
          modal: {
            displayDetails: "Mostrar detalles",
            resetButtonTitle: "Borrar búsqueda",
            backButtonTitle: "Cerrar búsqueda",
            noResultsText: "Sin resultados para",
            footer: { selectText: "seleccionar", navigateText: "moverse", closeText: "cerrar" },
          },
        },
      },
    },
    outline: { label: "En esta página" },
    docFooter: { prev: "Anterior", next: "Siguiente" },
    lastUpdated: { text: "Actualizado" },
    notFound: {
      title: "Página no encontrada",
      quote: "Esta página no existe o se ha movido.",
      linkText: "Volver al inicio",
    },
    darkModeSwitchLabel: "Apariencia",
    lightModeSwitchTitle: "Cambiar a modo claro",
    darkModeSwitchTitle: "Cambiar a modo oscuro",
    sidebarMenuLabel: "Menú",
    returnToTopLabel: "Volver arriba",
    externalLinkIcon: true,
  },
});
