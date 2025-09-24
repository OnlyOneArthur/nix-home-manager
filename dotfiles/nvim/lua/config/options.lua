-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.wrap = true

--make path at the top
vim.opt.winbar = "%=%m %f"

-- ignnore case sensitive word search
vim.opt.ignorecase = true

-- This forces Neovim to render ambiguous wide characters (like box-drawing) as 1 column, which keeps the ASCII art aligned.
-- vim.opt.ambiwidth = "single"
--
-- -- Make writes explicit (harmless for dashboard, useful elsewhere)
-- vim.opt.fileencoding = "utf-8"
-- vim.opt.fileencodings = { "utf-8" }
--
-- -- Ensure truecolor (some terminals need this for clean glyphs)
-- vim.opt.termguicolors = true
