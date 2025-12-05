return {
  "obsidian-nvim/obsidian.nvim",
  version = "*", -- recommended, use latest release instead of latest commit
  ft = "markdown",
  -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
  -- event = {
  --   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
  --   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/*.md"
  --   -- refer to `:h file-pattern` for more examples
  --   "BufReadPre path/to/my-vault/*.md",
  --   "BufNewFile path/to/my-vault/*.md",
  -- },
  ---@module 'obsidian'
  ---@type obsidian.config
  opts = {
    workspaces = {
      {
        name = "personal",
        path = "~/Obsidian/",
      },
    },

    --daily note
    daily_notes = {
      folder = "300 DailyNote",
      date_format = "%Y-%m-%d",
      alias_format = "%B %-d, %Y",
      default_tags = { "daily-notes" },
      template = nil,
    },

    new_notes_location = "current_dir",

    completion = {
      nvim_cmp = true,
    },
    ---@param title string|nil
    ---@return string
    note_id_func = function(title)
      -- Prefer PascalCase from title; otherwise timestamp fallback.
      local function to_pascal(s)
        s = (s or ""):gsub("[_%-%s]+", " "):gsub("[^%w%s]", "")
        local out = s:gsub("(%S)(%S*)", function(first, rest)
          return first:upper() .. rest:lower()
        end)
        return out:gsub("%s+", "")
      end
      if title and #vim.trim(title) > 0 then
        return to_pascal(title)
      end
      return os.date("%Y%m%d-%H%M%S")
    end,

    ---@param spec { id: string, dir: obsidian.Path, title: string|? }
    ---@return string|obsidian.Path
    note_path_func = function(spec)
      local path = spec.dir / tostring(spec.id)
      return path:with_suffix(".md")
    end,

    markdown_link_func = function(opts)
      return require("obsidian.util").markdown_link(opts)
    end,
    preferred_link_style = "wiki",

    disable_frontmatter = false,

    -- Optional, alternatively you can customize the frontmatter data.
    ---@return table
    note_frontmatter_func = function(note)
      -- Add the title of the note as an alias.
      if note.title then
        note:add_alias(note.title)
      end

      local out = {
        id = note.id,
        aliases = note.aliases,
        tags = note.tags,
        related = { "[[]]" },
        created = os.date("%Y-%m-%d %H:%M"),
      }

      -- `note.metadata` contains any manually added fields in the frontmatter.
      -- So here we just make sure those fields are kept in the frontmatter.
      if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
        for k, v in pairs(note.metadata) do
          out[k] = v
        end
      end

      return out
    end,

    templates = {
      folder = "templates",
    },

    picker = {
      -- Set your preferred picker. Can be one of 'telescope.nvim', 'fzf-lua', 'mini.pick' or 'snacks.pick'.
      name = "telescope.nvim",
      -- Optional, configure key mappings for the picker. These are the defaults.
      -- Not all pickers support all mappings.
      note_mappings = {
        -- Create a new note from your query.
        new = "<C-x>",
        -- Insert a link to the selected note.
        insert_link = "<C-l>",
      },
      tag_mappings = {
        -- Add tag(s) to current note.
        tag_note = "<C-x>",
        -- Insert a tag at the current location.
        insert_tag = "<C-l>",
      },
    },
  },
}
