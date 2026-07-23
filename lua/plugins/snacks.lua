return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        db = {
          sqlite3_path = vim.fn.stdpath("data") .. "/sqlite3.dll",
        },
        sources = {
          notifications = {
            win = {
              preview = {
                wo = {
                  wrap = true,
                  linebreak = true,
                  breakindent = true,
                },
              },
            },
          },
        },
      },
    },
  },
}
