-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- make costum command so that it auto make a dash(-) and the rest
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.formatoptions:append("r") -- `<CR>` in insert mode
    vim.opt_local.formatoptions:append("o") -- `o` in normal mode
    vim.opt_local.comments = {
      "b:- [ ]", -- tasks
      "b:- [x]",
      "b:*", -- unordered list
      "b:-",
      "b:+",
    }
  end,
})

--toggle off the markdown twiggle red line
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.spell = false
  end,
})

-- ~/.config/nvim/lua/config/autocmds.lua
-- Set filetype for .pde files
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = "*.pde",
  callback = function(args)
    vim.bo[args.buf].filetype = "processing"
  end,
})

-- Borrow Java Treesitter
vim.api.nvim_create_autocmd("FileType", {
  pattern = "processing",
  once = true,
  callback = function()
    pcall(function()
      vim.treesitter.language.register("java", "processing")
    end)
  end,
})

-- Setup keymaps for Processing
local grp = vim.api.nvim_create_augroup("ProcessingKeys", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = grp,
  pattern = "processing",
  callback = function(ev)
    local function map_opts(desc)
      return { buffer = ev.buf, desc = "Processing: " .. desc }
    end

    -- Helper function
    local function sketch_dir()
      local file = vim.api.nvim_buf_get_name(0)
      if file == "" then
        return vim.fn.getcwd()
      else
        return vim.fn.fnamemodify(file, ":p:h")
      end
    end

    local function pcli(args)
      local dir = sketch_dir()
      local cmd = { "processing", "cli", "--sketch=" .. dir }
      vim.list_extend(cmd, args)

      local Terminal = require("toggleterm.terminal").Terminal
      Terminal:new({
        cmd = table.concat(cmd, " "),
        dir = dir,
        direction = "float",
        close_on_exit = false,
        hidden = true,
      }):toggle()
    end

    vim.keymap.set("n", "<leader>pr", function()
      pcli({ "--run" })
    end, map_opts("Run"))
    vim.keymap.set("n", "<leader>pp", function()
      pcli({ "--present" })
    end, map_opts("Present (fullscreen)"))
    vim.keymap.set("n", "<leader>pb", function()
      pcli({ "--build" })
    end, map_opts("Build (.class only)"))
    vim.keymap.set("n", "<leader>pe", function()
      pcli({ "--output=build", "--export" })
    end, map_opts("Export → ./build"))
    vim.keymap.set("n", "<leader>pE", function()
      pcli({ "--output=build", "--force", "--export" })
    end, map_opts("Export (force)"))
  end,
})
