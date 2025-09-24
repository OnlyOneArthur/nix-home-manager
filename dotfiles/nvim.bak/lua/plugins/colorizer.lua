return {
  "catgoose/nvim-colorizer.lua",
  event = "BufReadPre",
  opts = {   -- set to setup table
    filetypes = { "css", "scss", "html", "javascript", "lua" },
    user_default_options = {
      names = true, -- enable named CSS colors like "red"
      rgb_fn = true,
      hsl_fn = true,
      css = true,
      css_fn = true,
    },
  },
}
