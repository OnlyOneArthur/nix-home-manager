-- -- Keymaps are automatically loaded on the verylazy event
-- -- default keymaps that are always set: https://github.com/lazyvim/lazyvim/blob/main/lua/lazyvim/config/keymaps.lua
-- -- add any additional keymaps here
-- --local util = require("lazyvim.util")
-- --local map = util.safe_keymap_set
-- --map("n", "<f5>", ":w | :termexec cmd='python3 %'<cr>", { desc = "run python file" })
--
-- --local util = require("lazyvim.util")
-- --local map = util.safe_keymap_set
-- --map("n", "<f5>", ":w | :term g++ % -o %:r && ./%:r<cr>", { desc = "compile and run c++ file" })
--
-- --local util = require("lazyvim.util")
-- --local map = util.safe_keymap_set
-- --map("n", "<f5>", ":w | :termexec cmd='g++ % -o %:r && ./%:r'<cr>", { desc = "compile and run c++ file" })
-- --local util = require("lazyvim.util")
-- --local map = util.safe_keymap_set
--
-- --map("n", "<f5>", function()
-- --  local filetype = vim.bo.filetype
-- --  if filetype == "python" then
-- --    vim.cmd(":w | :term python3 %")
-- --  elseif filetype == "cpp" then
-- --    vim.cmd(":w | :term g++ % -o %:r && ./%:r")
-- --  else
-- --    vim.notify("unsupported filetype: " .. filetype, vim.log.levels.warn)
-- --  end
-- --end, { desc = "run file (python or c++)" })
-- local util = require("lazyvim.util")
-- local map = util.safe_keymap_set
--
-- map("n", "<f5>", function()
--   local filetype = vim.bo.filetype
--   -- set working directory to the file's directory
--   vim.cmd(":cd %:p:h")
--   if filetype == "python" then
--     vim.cmd(":w | :term python3 %")
--   elseif filetype == "cpp" then
--     vim.cmd(":w | :term g++ % -o %:r && ./%:r || echo 'compilation failed'")
--   else
--     vim.notify("unsupported filetype: " .. filetype, vim.log.levels.warn)
--   end
-- end, { desc = "run file (python or c++)" })
--
-- -- Optional: Close terminal buffer
-- map("n", "<leader>tc", ":bd!<CR>", { desc = "Close Terminal" })

local Util = require("lazyvim.util")
local map = Util.safe_keymap_set

map("n", "<leader>cc", function()
  local filetype = vim.bo.filetype
  -- Set working directory to the file's directory
  vim.cmd(":cd %:p:h")
  if filetype == "python" then
    vim.cmd(":w | :term python3 %")
  elseif filetype == "cpp" then
    vim.cmd(":w | :term g++ % -o %:r && chmod +x %:r && ./%:r || echo 'Compilation failed'")
  elseif filetype == "java" then
    vim.cmd(":w | :term javac % && java %:r || echo 'Compilation failed'")
  else
    vim.notify("Unsupported filetype: " .. filetype, vim.log.levels.WARN)
  end
end, { desc = "Run File (Python, C++, or Java)" })

-- Optional: Close terminal buffer
map("n", "<leader>tc", ":bd!<CR>", { desc = "Close Terminal" })

local map = vim.keymap.set

-- Live Server
map("n", "<leader>ls", "<cmd>LiveServerStart<cr>", { desc = "Start Live Server" })
map("n", "<leader>lS", "<cmd>LiveServerStop<cr>", { desc = "Stop Live Server" })

--ToggleTerm keymap

-- ToggleTerm keymaps
local map = vim.keymap.set

map("n", "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", { desc = "Terminal (float)" })
map("n", "<leader>th", "<cmd>ToggleTerm size=15 direction=horizontal<cr>", { desc = "Terminal (horizontal)" })
map("n", "<leader>tv", "<cmd>ToggleTerm size=60 direction=vertical<cr>", { desc = "Terminal (vertical)" })

vim.api.nvim_set_keymap("n", "<leader>n", "<cmd>ASToggle<CR>", {})

-- telescope costum keymaps

--- lua/config/keymaps.lua or inside the obsidian spec's `keys = { ... }`
vim.keymap.set("n", "<leader>oq", "<cmd>Obsidian quick_switch<cr>", { desc = "Obsidian Quick Switch" })
vim.keymap.set("n", "<leader>os", "<cmd>Obsidian search<cr>", { desc = "Obsidian Search" })
vim.keymap.set("n", "<leader>ob", "<cmd>Obsidian backlinks<cr>", { desc = "Obsidian Backlinks" })
vim.keymap.set("n", "<leader>ol", "<cmd>Obsidian links<cr>", { desc = "Obsidian Links (in file)" })
vim.keymap.set("n", "<leader>on", "<cmd>Obsidian new<cr>", { desc = "Obsidian new from templates" })

-- -- remap ot to auto add Note templates
-- vim.keymap.set("n", "<leader>ot", function()
--   vim.cmd("Obsidian template Note")
--   local LINE_NUM = 9
--   local line = vim.fn.getline(LINE_NUM)
--   local title = line:match("# (.*)")
--
--   if title then
--     title = title:gsub("_%d%d%d%d%-%d%d%-%d%d$", "")
--     title = title:gsub("[_%-]", " ")
--     title = title:gsub("%s+$", "")
--     vim.fn.setline(LINE_NUM, "# " .. title)
--   end
--
--   vim.cmd("noh")
-- end, { desc = "Insert Template" })
