return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        db = {
          sqlite3_path = vim.fn.stdpath("data") .. "/sqlite3.dll",
        },
      },
    },
  },
}
