require('kvim.utils.devices')
local n = require("nui-components")
local vars = require('kvim.config.environment-vars')

local ssh = n.create_signal({ targetIp = '', targetPath = '', targetUser = ''})

local function save_ssh()
    setConfigField(ssh:get_value().targetIp, vars.id.SSH, vars.key.SSH_IP)
    setConfigField(ssh:get_value().targetPath, vars.id.SSH, vars.key.SSH_PATH)
    setConfigField(ssh:get_value().targetUser, vars.id.SSH, vars.key.SSH_USER)
end

function config_ssh()
    -- el env debería de ser global para acceder desde cualquier lado
    ssh.targetIp = getConfigField(vars.id.SSH, vars.key.SSH_IP)
    ssh.targetPath = getConfigField(vars.id.SSH, vars.key.SSH_PATH)
    ssh.targetUser = getConfigField(vars.id.SSH, vars.key.SSH_USER)
    return n.form(
	{
	    id = "ssh-settings",
	    submit_key = "<c-cr>",
	    on_submit = function(_)
		save_ssh()
	    end,
	},
	n.gap(1),
	n.paragraph({
	    autofocus = true,
	    lines = "SSH Configurator",
	    align ="center",
	}),
	n.gap(1),
	n.paragraph({lines = {
	    n.line(n.text("⚠️ Please ensure that the SSH authentication details are correct before", "Italic")),
	    n.line(n.text("  proceeding (ssh-keygen + ssh-copy-id + authenticate).", "Italic"))
	    }}),
	n.gap(1),
	n.text_input({
	    flex = 1,
	    border_label = "SSH IP",
	    value = ssh:get_value().targetIp,
	    on_change = function(value)
		ssh.targetIp = value
	    end,
	}),
	n.text_input({
	    flex = 1,
	    border_label = "SSH User",
	    value = ssh:get_value().targetUser,
	    on_change = function(value)
		ssh.targetUser = value
	    end,
	}),
	n.text_input({
	    flex = 1,
	    border_label = "SSH Path",
	    value = ssh:get_value().targetPath,
	    on_change = function(value)
		ssh.targetPath = value
	    end,
	}),
	n.columns(
	    n.button({
		label = "Back",
		on_press = function ()
		end,
	    }),
	    n.gap(3),
	    n.button({
		label = "Save",
		on_press = function ()
		    save_ssh()
		end,
	    }),
	    n.gap(3),
	    n.button({
		label = "Exit",
		on_press = function ()
		end,
	    })
	)
    )
end

