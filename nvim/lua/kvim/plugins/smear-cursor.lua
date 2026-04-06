-- smear-cursor.nvim: Efecto de cursor con estela
-- Añade un efecto visual de "arrastre" al mover el cursor
return {
	"sphamba/smear-cursor.nvim",
    lazy = true,                            -- Carga perezosa
    event = "UIEnter",                      -- Se carga cuando la UI está lista
	opts = {
		stiffness = 0.5,           -- Rigidez del cursor (0-1, menor = más flexible)
		trailing_stiffness = 0.49, -- Rigidez de la estela (efecto de cola)
        never_draw_over_target = false -- No dibujar sobre el objetivo
	},
}
