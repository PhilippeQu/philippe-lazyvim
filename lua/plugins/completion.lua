return {
  {
    "saghen/blink.cmp",
    opts = {
      completion = {
        menu = {
          auto_show = function()
            return vim.bo.filetype ~= "markdown" and vim.bo.filetype ~= "markdown.mdx"
          end,
        },
      },
    },
  },
}
