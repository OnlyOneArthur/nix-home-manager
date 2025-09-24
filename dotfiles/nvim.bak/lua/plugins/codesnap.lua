return {
  "mistricky/codesnap.nvim",
  build = "make",
  config = function()
    require("codesnap").setup({
      watermark = "",
      save_path = "~Picture/CodeSnap",
      bg_theme = "grape",
    })
  end,
}
