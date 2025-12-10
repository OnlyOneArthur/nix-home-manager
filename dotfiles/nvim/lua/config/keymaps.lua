-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua

-- terminal keymaps
local map = vim.keymap.set

map("n", "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", { desc = "Terminal (float)" })
map("n", "<leader>th", "<cmd>ToggleTerm size=15 direction=horizontal<cr>", { desc = "Terminal (horizontal)" })
map("n", "<leader>tv", "<cmd>ToggleTerm size=60 direction=vertical<cr>", { desc = "Terminal (vertical)" })

-- obsidian keymap
vim.keymap.set("n", "<leader>oq", "<cmd>Obsidian quick_switch<cr>", { desc = "Obsidian Quick Switch" })
vim.keymap.set("n", "<leader>os", "<cmd>Obsidian search<cr>", { desc = "Obsidian Search" })
vim.keymap.set("n", "<leader>ob", "<cmd>Obsidian backlinks<cr>", { desc = "Obsidian Backlinks" })
vim.keymap.set("n", "<leader>ol", "<cmd>Obsidian links<cr>", { desc = "Obsidian Links (in file)" })
vim.keymap.set("n", "<leader>on", "<cmd>Obsidian new<cr>", { desc = "Obsidian new from templates" })

-- copilot assistant keymaps

-- contoh mapping untuk menerima suggestion Copilot melalui LazyVim + copilot.lua
local cmp = require("cmp")
vim.keymap.set("i", "<S-Tab>", function()
  if require("copilot.suggestion").is_visible() then
    require("copilot.suggestion").accept()
  else
    cmp.mapping.select_prev_item()(vim.api.nvim_get_current_buf())
  end
end, { desc = "Accept Copilot suggestion or select previous item" })

-- Copilot Chat keymaps

vim.keymap.set("n", "<leader>zc", "<Cmd>CopilotChat<CR>", { desc = "Chat with Copilot" })
vim.keymap.set("v", "<leader>ze", "<Cmd>CopilotChatExplain<CR>", { desc = "Explain Code" })
vim.keymap.set("v", "<leader>zr", "<Cmd>CopilotChatReview<CR>", { desc = "Review Code" })
vim.keymap.set("v", "<leader>zf", "<Cmd>CopilotChatFix<CR>", { desc = "Fix Code Issues" })
vim.keymap.set("v", "<leader>zo", "<Cmd>CopilotChatOptimize<CR>", { desc = "Optimize Code" })
vim.keymap.set("v", "<leader>zd", "<Cmd>CopilotChatDocs<CR>", { desc = "Generate Docs" })
vim.keymap.set("v", "<leader>zt", "<Cmd>CopilotChatTests<CR>", { desc = "Generate Tests" })
vim.keymap.set("n", "<leader>zm", "<Cmd>CopilotChatCommit<CR>", { desc = "Generate Commit Message" })
vim.keymap.set("v", "<leader>zs", "<Cmd>CopilotChatCommit<CR>", { desc = "Generate Commit for Selection" })

-- autosave plugins
vim.api.nvim_set_keymap("n", "<leader>as", "<cmd>ASToggle<CR>", {})

-- live server plugins
vim.api.nvim_set_keymap("n", "<leader>ls", "<cmd>LiveServerStart<CR>", {})
vim.api.nvim_set_keymap("n", "<leader>lq", "<cmd>LiveServerStop<CR>", {})
