return { {
    baudrate = 115200,
    command = "picocom",
    device = "/dev/ttyACM0",
    name = "ESP32-C6 RCP",
    tags = { "embedded", "thread" },
    type = "serial"
  }, {
    host = "127.0.0.1",
    identity_file = "/home/KODVMV/.ssh/kvim_docker-test-1_ed25519",
    name = "docker-test-1",
    options = {
      IdentitiesOnly = "yes"
    },
    port = 2222,
    type = "ssh",
    user = "test"
  }, {
    host = "127.0.0.1",
    identity_file = "/home/KODVMV/.ssh/kvim_docker-test-2_ed25519",
    name = "docker-test-2",
    options = {
      IdentitiesOnly = "yes"
    },
    port = 2223,
    type = "ssh",
    user = "test2"
  } }

