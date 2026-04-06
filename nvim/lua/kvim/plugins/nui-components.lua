-- nui-components.nvim: Componentes UI reutilizables
-- Proporciona componentes (botones, menús, etc.) para crear interfaces
return {
  "grapp-dev/nui-components.nvim",
  dependencies = {
    "MunifTanjim/nui.nvim" -- Framework base para componentes UI
  },
  lazy = true,         -- Carga perezosa
  event = "VeryLazy",  -- Se carga después de iniciar
}
