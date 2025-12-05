return {
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
      { "nvim-lua/plenary.nvim", branch = "master" },
    },
    build = "make tiktoken",
    opts = {
      temperature = 0.3,
      window = {
        layout = "vertical",
        width = 0.3,
      },
      auto_insert_mode = true,
      -- See Configuration section for options
    },
    config = function(_, opts)
      require("CopilotChat").setup(opts)
    end,
  },
}
