-- ~/.config/nvim/lua/plugins/processing.lua
-- Processing (4.4+) CLI integration for LazyVim without jdtls noise.
-- - filetype=processing (no Java LSP)
-- - Treesitter highlights borrowed from Java
-- - toggleterm runner using `processing cli`

return {
  -- Terminal manager
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    opts = {
      size = 12,
      open_mapping = [[<c-\>]],
      shade_terminals = true,
    },
    config = function(_, opts)
      require("toggleterm").setup(opts)
      local Terminal = require("toggleterm.terminal").Terminal

      -- Treat *.pde as a distinct filetype = "processing"
      vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
        pattern = "*.pde",
        callback = function(args)
          vim.bo[args.buf].filetype = "processing"
        end,
      })

      -- Borrow Java Treesitter for the "processing" filetype
      pcall(function()
        -- Neovim 0.9+ API
        vim.treesitter.language.register("java", "processing")
      end)

      -- Resolve the sketch directory: fallback to cwd for unnamed buffers
      local function sketch_dir()
        local file = vim.api.nvim_buf_get_name(0)
        if file == "" then
          return vim.fn.getcwd()
        else
          return vim.fn.fnamemodify(file, ":p:h")
        end
      end

      -- Build and run `processing cli` in a managed terminal
      local function pcli(args)
        local dir = sketch_dir()
        local cmd = { "processing", "cli", "--sketch=" .. dir }
        vim.list_extend(cmd, args)

        Terminal:new({
          cmd = table.concat(cmd, " "),
          dir = dir,
          direction = "float", -- or "horizontal" / "vertical"
          close_on_exit = false,
          hidden = true,
        }):toggle()
      end

      -- Buffer-local keymaps for Processing files
      local grp = vim.api.nvim_create_augroup("ProcessingKeys", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        group = grp,
        pattern = { "processing" },
        callback = function(ev)
          local function map_opts(desc)
            return { buffer = ev.buf, desc = "Processing: " .. desc }
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
    end,
  },

  -- Ensure Java Treesitter (used for "processing" via language.register)
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
