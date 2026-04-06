-- flutter-tools.nvim: Integración con Flutter/Dart
-- Proporciona comandos, diagnóstico y herramientas para desarrollo Flutter
return {
	"nvim-flutter/flutter-tools.nvim",
	lazy = true,                         -- Carga perezosa
	ft = { "dart" },                     -- Solo se carga para archivos Dart/Flutter
	dependencies = {
		"nvim-lua/plenary.nvim",  -- Dependencia común para plugins Lua
		"stevearc/dressing.nvim", -- Mejora vim.ui.select con UI nativa
	},
	config = true, -- Habilita configuración por defecto
}
