return {
  disk_mount = "disk",
  github = {
    owner = "Damian-Narcis-Ionel",
    repo = "cc-storage",
    branch = "main",
  },

  programs = {
    labels = {
      file = "labels.lua",
      path = "labels.lua",
    },

    setup_storage = {
      file = "setup_storage.lua",
      path = "setup_storage.lua",
    },

    sorter = {
      file = "sorter.lua",
      path = "sorter.lua",
    },

    dashboard = {
      file = "dashboard.lua",
      path = "dashboard.lua",
    },

    updater = {
      file = "updater.lua",
      path = "updater.lua",
    },
  },

  configs = {
    updater_config = {
      file = "updater_config.lua",
      path = "updater_config.lua",
      target = "/updater_config.lua",
    },

    sorter_config = {
      file = "sorter_config.lua",
      path = "sorter_config.lua",
      target = "/sorter_config.lua",
      preserve_existing = true,
    },
  }
}
