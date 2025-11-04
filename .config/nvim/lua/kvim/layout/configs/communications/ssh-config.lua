require("kvim.utils.devices")
local n = require("nui-components")
local vars = require("kvim.config.environment-vars")

local ssh = n.create_signal({
    ip = {""},
    port = {""},
    path = {""},
    user = {""},
    key_type = {""}
})

local function save_ssh()
	setConfigField(ssh:get_value().ip, vars.id.SSH, vars.key.SSH_IP)
	setConfigField(ssh:get_value().port, vars.id.SSH, vars.key.SSH_PORT)
	setConfigField(ssh:get_value().user, vars.id.SSH, vars.key.SSH_USER)
	setConfigField(ssh:get_value().path, vars.id.SSH, vars.key.SSH_PATH)
	setConfigField(ssh:get_value().key_type, vars.id.SSH, vars.key.SSH_KEY_TYPE)
	share_pub_key(ssh:get_value().key_type, ssh:get_value().user, ssh:get_value().ip, ssh:get_value().port)
end

local function update_ssh_field(field, value)
    local current = ssh:get_value()
    current[field] = value
    ssh:set_value(current)
end

function config_ssh()
	-- el env debería de ser global para acceder desde cualquier lado
    ssh:set_value({
        ip = getConfigField(vars.id.SSH, vars.key.SSH_IP),
        port = getConfigField(vars.id.SSH, vars.key.SSH_PORT),
        user = getConfigField(vars.id.SSH, vars.key.SSH_USER),
        path = getConfigField(vars.id.SSH, vars.key.SSH_PATH),
        key_type = getConfigField(vars.id.SSH, vars.key.SSH_KEY_TYPE),
    })
    getConfigField(vars.id.SSH, vars.key.SSH_KEY_TYPE)
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
			align = "center",
		}),
		n.gap(1),
        n.select({
            border_label = "Key Type",
            selected = ssh.key_type,
            data = {
                n.option("rsa", { id = "rsa"}),
                n.option("dsa", { id = "dsa"}),
                n.option("ecdsa", { id = "ecdsa"}),
                n.option("ecdsa-sk", { id = "ecdsa-sk"}),
                n.option("ed25519", { id = "ed25519"}),
                n.option("ed25519-sk", { id = "ed25519-sk"}),
            },
            on_select = function(node, _)
                update_ssh_field("key_type", node.text)
            end,
        }),
		n.text_input({
			flex = 1,
			border_label = "Port",
			value = ssh:get_value().port,
			on_change = function(port)
                update_ssh_field("port", port)
			end,
		}),
		n.text_input({
			flex = 1,
			border_label = "Ip",
			value = ssh:get_value().ip,
			on_change = function(ip)
                update_ssh_field("ip", ip)
			end,
		}),
		n.text_input({
			flex = 1,
			border_label = "User",
			value = ssh:get_value().user,
			on_change = function(user)
                update_ssh_field("user", user)
			end,
		}),
		n.text_input({
			flex = 1,
			border_label = "Path",
			value = ssh:get_value().path,
			on_change = function(path)
                update_ssh_field("path", path)
			end,
		}),
		n.columns(
			n.button({
				label = "Back",
				on_press = function() end,
			}),
			n.gap(3),
			n.button({
				label = "Save",
				on_press = function()
					save_ssh()
				end,
			}),
			n.gap(3),
			n.button({
				label = "Exit",
				on_press = function() end,
			})
		)
	)
end
