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
}
