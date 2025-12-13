return {
  "CRAG666/code_runner.nvim",
  config = function()
    require("code_runner").setup({
      focus = true,

      -- Start in insert mode when opening terminal
      startinsert = true,

      -- Terminal settings
      term = {
        position = "bot", -- Options: "vert", "bot"
        size = 15, -- Terminal size (height for bot, width for vert)
      },

      -- Float window settings
      float = {
        border = "rounded", -- Options: "none", "single", "double", "rounded", "solid", "shadow"
        height = 0.8,
        width = 0.8,
        x = 0.5,
        y = 0.5,
        border_hl = "FloatBorder",
        blend = 0,
      },

      -- File type commands
      filetype = {
        -- Interpreted languages
        python = "python3 -u",
        javascript = "node",
        typescript = "ts-node",
        lua = "lua",
        ruby = "ruby",
        perl = "perl",
        php = "php",
        r = "Rscript",
        bash = "bash",
        sh = "sh",

        -- Compiled languages with build steps
        java = {
          "cd $dir &&",
          "javac $fileName &&",
          "java $fileNameWithoutExt",
        },

        c = {
          "cd $dir &&",
          "gcc $fileName -o /tmp/$fileNameWithoutExt &&",
          "/tmp/$fileNameWithoutExt",
        },

        cpp = {
          "cd $dir &&",
          "g++ $fileName -o /tmp/$fileNameWithoutExt &&",
          "/tmp/$fileNameWithoutExt",
        },

        rust = {
          "cd $dir &&",
          "rustc $fileName &&",
          "$dir/$fileNameWithoutExt",
        },

        go = "go run",

        kotlin = {
          "cd $dir &&",
          "kotlinc $fileName -include-runtime -d $fileNameWithoutExt.jar &&",
          "java -jar $fileNameWithoutExt.jar",
        },

        swift = "swift",

        vim = ":source %",
      },
    })
  end,
}
