local markdownlint_config = vim.fn.stdpath("config") .. "/markdownlint-cli2.yaml"

return {
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters = {
        ["markdownlint-cli2"] = {
          args = { "-", "--config", markdownlint_config },
        },
      },
      linters_by_ft = {
        markdown = { "markdownlint-cli2" },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters = {
        ["markdownlint-cli2"] = {
          args = { "$FILENAME", "--config", markdownlint_config, "--fix" },
        },
      },
    },
  },
}
