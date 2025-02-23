require('kvim.utils.devices')
local n = require("nui-components")
local vars = require('kvim.config.environment-vars')

local ssh = n.create_signal({ targetIp = '', targetDir = '', targetUser = '', targetPass = ''})

local function save_ssh_config(targetIp, targetDir, targetUser, targetPass)
    setConfigField(targetIp, vars.id.SSH, vars.key.TARGET_IP)
    setConfigField(targetDir, vars.id.SSH, vars.key.TARGET_DIR)
    setConfigField(targetUser, vars.id.SSH, vars.key.TARGET_USER)
    setConfigField(targetPass, vars.id.SSH, vars.key.TARGET_PASS)
end

function ssh_config(render)
    -- el env debería de ser global para acceder desde cualquier lado
    ssh.targetIp = getConfigField(vars.id.SSH, vars.key.TARGET_IP)
    ssh.targetDir = getConfigField(vars.id.SSH, vars.key.TARGET_DIR)
    ssh.targetUser = getConfigField(vars.id.SSH, vars.key.TARGET_USER)
    ssh.targetPass = getConfigField(vars.id.SSH, vars.key.TARGET_PASS)
    return n.form(
	{
	    id = "ssh-settings",
	    submit_key = "<c-cr>",
	    on_submit = function(_)
		save_ssh_config(ssh.targetIp:get_value(), ssh.targetDir:get_value(), ssh.targetUser:get_value())
		render:close()
	    end,
	},
	n.text_input({
	    flex = 1,
	    border_label = "User",
	    value = ssh.targetUser,
	    on_change = function(value)
		ssh.targetUser = value
	    end,
	}),
	n.text_input({
	    flex = 1,
	    border_label = "Target IP",
	    value = ssh.targetIp,
	    on_change = function(value)
		ssh.targetIp = value
	    end,
	}),
	n.text_input({
	    flex = 1,
	    border_label = "Target Directory",
	    value = ssh.targetDir,
	    on_change = function(value)
		ssh.targetDir = value
	    end,
	})
    )
end
