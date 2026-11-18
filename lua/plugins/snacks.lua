return {
  {
    "folke/snacks.nvim",
    opts = {
      terminal = {
        -- cmd can launch the Microsoft Store alias when Neovim cannot resolve it.
        shell = vim.fn.executable("pwsh") == 1 and "pwsh" or { "cmd.exe", "/d", "/c", "pwsh.exe" },
      },
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
