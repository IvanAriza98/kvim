require('utils.devices')

local n = require("nui-components")
local vars = require('config.environment-vars')

local ssh = n.create_signal({ targetIp = '', targetDir = '' })

local function save_ssh_config()
    setConfigField(ssh:get_value().targetIp, vars.id.SSH, vars.key.TARGET_IP)
    setConfigField(ssh:get_value().targetDir, vars.id.SSH, vars.key.TARGET_DIR)
end

function ssh_config(render)
    -- el env debería de ser global para acceder desde cualquier lado
    ssh.targetIp = getConfigField(vars.id.SSH, vars.key.TARGET_IP)
    ssh.targetDir = getConfigField(vars.id.SSH, vars.key.TARGET_DIR)
    
    return n.form(
	{
	    id = "ssh-settings",
	    submit_key = "<c-cr>",
	    on_submit = function(is_valid)
		save_ssh_config()
		render:close()
	    end,
	},
	n.text_input({
	    flex = 1,
	    border_label = "Target IP",
	    value = ssh.targetIp,
	    on_change = function(value, component)
		ssh.targetIp = value
	    end,
	}),
	n.text_input({
	    flex = 1,
	    border_label = "Target Directory",
	    value = ssh.targetDir,
	    on_change = function(value, component)
		ssh.targetDir = value
	    end,
	})
    )
end
