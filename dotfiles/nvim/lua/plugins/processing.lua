-- ~/.config/nvim/lua/plugins/processing.lua
return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    event = "VeryLazy", -- Add this
    opts = {
      size = 12,
      open_mapping = [[<c-\>]],
      shade_terminals = true,
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, o)
      o.ensure_installed = o.ensure_installed or {}
      if not vim.tbl_contains(o.ensure_installed, "java") then
        table.insert(o.ensure_installed, "java")
      end
    end,
  },
}
