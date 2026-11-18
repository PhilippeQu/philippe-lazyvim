-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local markdown_spell = vim.api.nvim_create_augroup("user_markdown_spell", { clear = true })

local function disable_markdown_spell()
  vim.opt_local.spell = false
  vim.opt_local.spelllang = { "en", "cjk" }
end

vim.api.nvim_create_autocmd("FileType", {
  group = markdown_spell,
  pattern = { "markdown", "markdown.mdx" },
  callback = disable_markdown_spell,
})

-- Some .mdx buffers open without a detected filetype.
vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  group = markdown_spell,
  pattern = "*.mdx",
  callback = disable_markdown_spell,
})
