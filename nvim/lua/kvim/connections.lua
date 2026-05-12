return {
  {
    name = "Docker SSH Test",
    type = "ssh",
    host = "127.0.0.1",
    user = "test",
    port = 2222,
    identity_file = "~/.ssh/kvim_connections_ed25519",
    tags = { "ssh-test", "docker" },
    transfer = {
        method = "scp",
        local_root = vim.fn.getcwd(),
        remote_root = "/config/new",
        remote_file = "/config/new/AGENTS2.md",
    },
  },

  {
    name = "Docker SSH test 2",
    type = "ssh",
    host = "127.0.0.1",
    user = "test2",
    port = 2223,
    identity_file = "~/.ssh/kvim_docker_ssh_test_2_ed25519",
    tags = { "ssh-test", "docker" },
  },

  {
    name = "ESP32-C6 RCP",
    type = "serial",
    device = "/dev/ttyACM0",
    baudrate = 115200,
    command = "picocom",
    tags = { "embedded", "thread" },
  },
}
