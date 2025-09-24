-- ~/.config/nvim/lua/plugins/cord.lua
return {
  "vyfor/cord.nvim",
  lazy = false, -- load early so nothing else overrides it
  priority = 1000,
  build = ":Cord update",
  config = function()
    require("cord").setup({
      editor = {
        client = "neovim", -- keep Neovim client
      },
      display = {
        view = "full", -- only show the editor icon (no filetype/asset icon)
        swap_fields = false,
        swap_icons = false,
      },
      timestamp = {
        enabled = true, -- kill the green timer
        reset_on_change = false,
        reset_on_idle = false,
        shared = true,
      },
      -- Crucial: blank out every activity text that could inject filename/path
      text = {
        default = "Using Neovim",
        workspace = "", -- was "In {workspace}"
        viewing = "", -- was "Viewing {filename}"
        editing = "", -- was "Editing {filename}"
        file_browser = "",
        plugin_manager = "",
        lsp = "",
        docs = "",
        vcs = "",
        notes = "",
        debug = "",
        test = "",
        diagnostics = "",
        games = "",
        terminal = "",
        dashboard = "Using Neovim",
      },
    })
  end,
}
