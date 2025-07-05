require('kvim.utils.devices')
local n = require("nui-components")
local vars = require('kvim.config.environment-vars')

local ssh = n.create_signal({ ip = '', port = '', path = '', user = ''})

local function save_ssh()
    setConfigField(ssh:get_value().ip, vars.id.SSH, vars.key.SSH_IP)
    setConfigField(ssh:get_value().port, vars.id.SSH, vars.key.SSH_PORT)
    setConfigField(ssh:get_value().user, vars.id.SSH, vars.key.SSH_USER)
    setConfigField(ssh:get_value().path, vars.id.SSH, vars.key.SSH_PATH)

    share_pub_key(ssh:get_value().user, ssh:get_value().ip, ssh:get_value().port)
end

function config_ssh()
    -- el env debería de ser global para acceder desde cualquier lado
    ssh.ip = getConfigField(vars.id.SSH, vars.key.SSH_IP)
    ssh.port = getConfigField(vars.id.SSH, vars.key.SSH_PORT)
    ssh.user = getConfigField(vars.id.SSH, vars.key.SSH_USER)
    ssh.path = getConfigField(vars.id.SSH, vars.key.SSH_PATH)
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
	n.text_input({
	    flex = 1,
	    border_label = "Port",
	    value = ssh:get_value().port,
	    on_change = function(value)
		ssh.port = value
	    end,
	}),
	n.text_input({
	    flex = 1,
	    border_label = "Ip",
	    value = ssh:get_value().ip,
	    on_change = function(value)
		ssh.ip = value
	    end,
	}),
	n.text_input({
	    flex = 1,
	    border_label = "User",
	    value = ssh:get_value().user,
	    on_change = function(value)
		ssh.user = value
	    end,
	}),
	n.text_input({
	    flex = 1,
	    border_label = "Path",
	    value = ssh:get_value().path,
	    on_change = function(value)
		ssh.path = value
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

