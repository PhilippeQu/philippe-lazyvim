local show_dotfiles = true

local noise_names = {
  ["__pycache__"] = true,
  [".pytest_cache"] = true,
  [".mypy_cache"] = true,
  [".ruff_cache"] = true,
  [".tox"] = true,
  [".nox"] = true,
  [".venv"] = true,
  ["venv"] = true,
  ["env"] = true,
  ["node_modules"] = true,
  [".next"] = true,
  [".nuxt"] = true,
  ["dist"] = true,
  ["build"] = true,
  ["coverage"] = true,
  [".cache"] = true,
  ["target"] = true,
  [".gradle"] = true,
  [".idea"] = true,
  [".vscode"] = true,
  [".DS_Store"] = true,
}

local function entry_name(fs_entry)
  return fs_entry.name or vim.fs.basename(fs_entry.path)
end

local function is_noise_file(name)
  return noise_names[name] or name:match("%.pyc$") ~= nil
end

local function mini_files_filter(fs_entry)
  local name = entry_name(fs_entry)

  if not show_dotfiles and vim.startswith(name, ".") then
    return false
  end

  if vim.g.mini_files_hide_noise ~= false and is_noise_file(name) then
    return false
  end

  return true
end

local function refresh_mini_files()
  local ok, mini_files = pcall(require, "mini.files")
  if ok then
    mini_files.refresh({ content = { filter = mini_files_filter } })
  end
end

return {
  {
    "nvim-mini/mini.files",
    opts = function(_, opts)
      vim.g.mini_files_hide_noise = vim.g.mini_files_hide_noise ~= false
      opts.content = opts.content or {}
      opts.content.filter = mini_files_filter
    end,
    keys = {
      {
        "<leader>uH",
        function()
          vim.g.mini_files_hide_noise = not vim.g.mini_files_hide_noise
          refresh_mini_files()
          vim.notify(
            vim.g.mini_files_hide_noise and "Hiding development noise" or "Showing development noise",
            vim.log.levels.INFO,
            { title = "mini.files" }
          )
        end,
        desc = "Toggle Hidden Dev Files",
      },
    },
    init = function()
      vim.g.mini_files_hide_noise = vim.g.mini_files_hide_noise ~= false

      vim.api.nvim_create_autocmd("User", {
        group = vim.api.nvim_create_augroup("user_mini_files_filter", { clear = true }),
        pattern = "MiniFilesBufferCreate",
        callback = function(args)
          vim.schedule(function()
            local buf_id = args.data.buf_id
            if not vim.api.nvim_buf_is_valid(buf_id) then
              return
            end

            vim.keymap.set("n", "g.", function()
              show_dotfiles = not show_dotfiles
              refresh_mini_files()
            end, { buffer = buf_id, desc = "Toggle hidden files" })
          end)
        end,
      })
    end,
  },
}
