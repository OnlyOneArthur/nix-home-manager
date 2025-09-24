-- ~/.config/nvim/lua/plugins/auto-save.lua
return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
      require("toggleterm").setup({
        size = 15,
        shade_terminals = true,
        start_in_insert = true,
      })
    end,
  },

  -- { "ellisonleao/gruvbox.nvim" },
  --
  -- -- Configure LazyVim to load gruvbox
  -- {
  --   "LazyVim/LazyVim",
  --   opts = {
  --     colorscheme = "gruvbox",
  --   },
  -- },

  --Live-server plugin
  {
    "barrett-ruth/live-server.nvim",
    build = "pnpm add -g live-server",
    cmd = { "LiveServerStart", "LiveServerStop" },
    config = true,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- add tsx and treesitter
      vim.list_extend(opts.ensure_installed, {
        "javascript",
        "bash",
        "lua",
        "css",
        "tsx",
        "xml",
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- JavaScript / TypeScript
        tsserver = {},

        -- CSS
        cssls = {},
      },
    },
  },
}
