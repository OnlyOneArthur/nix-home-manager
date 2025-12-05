-- lua/plugins/telescope.lua

return {
  {
    "nvim-telescope/telescope.nvim",
    version = false,
    dependencies = {
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    opts = {
      defaults = {
        layout_strategy = "vertical",
      },
    },
    -- Define keys here so LazyVim loads Telescope on first use, and so we can set nowait
    keys = function()
      local builtin = require("telescope.builtin")

      -- robust $HOME detection across Neovim/libuv variants
      local uv = vim.uv or vim.loop
      local HOME = (uv and uv.os_homedir and uv.os_homedir()) or vim.env.HOME or vim.fn.expand("~")

      return {
        -- <leader>f → search HOME (nowait avoids which-key delay/capture)
        {
          "<leader>F",
          function()
            builtin.find_files({ cwd = HOME })
          end,
          desc = "Find files in $HOME",
          mode = "n",
          nowait = true,
          silent = true,
        },
      }
    end,
    config = function(_, opts)
      local telescope = require("telescope")
      telescope.setup(opts)
      pcall(telescope.load_extension, "fzf") -- don't explode if build failed
    end,
  },
}
