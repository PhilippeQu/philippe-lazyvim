local uv = vim.uv or vim.loop

local state_dir = vim.fs.joinpath(vim.env.LOCALAPPDATA, "nvim-ime")
local state_file = vim.fs.joinpath(state_dir, "state.txt")

local current_id
local watcher
local poller
local read_scheduled = false

local labels = {
  ["1033"] = "Ⓐ 英",
  ["2052"] = "㊥ 中",
}

local function refresh_lualine()
  if package.loaded.lualine then
    require("lualine").refresh({ place = { "statusline" } })
  end
end

local function set_state(id)
  id = id and id:match("%d+")
  if not labels[id] or id == current_id then
    return
  end

  current_id = id
  refresh_lualine()
end

local function read_state()
  local file = io.open(state_file, "rb")
  if not file then
    return false
  end

  local value = file:read("*a")
  file:close()
  set_state(value)
  return true
end

local function schedule_read()
  if read_scheduled then
    return
  end

  read_scheduled = true
  vim.defer_fn(function()
    read_scheduled = false
    read_state()
  end, 20)
end

local function start_watcher()
  if watcher then
    return
  end

  vim.fn.mkdir(state_dir, "p")
  read_state()

  watcher = uv.new_fs_event()
  if not watcher then
    return
  end

  local ok = watcher:start(state_dir, {}, function(err)
    if not err then
      vim.schedule(schedule_read)
    end
  end)

  if not ok then
    watcher:close()
    watcher = nil
  end

  -- A small polling fallback covers Windows file-system events occasionally
  -- missed when AutoHotkey atomically replaces the state file.
  poller = uv.new_timer()
  if poller then
    poller:start(250, 250, vim.schedule_wrap(schedule_read))
  end

  vim.api.nvim_create_autocmd({ "FocusGained", "VimResume" }, {
    callback = schedule_read,
    desc = "Refresh the cached Windows input method",
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    once = true,
    callback = function()
      if watcher then
        watcher:stop()
        if not watcher:is_closing() then
          watcher:close()
        end
        watcher = nil
      end
      if poller then
        poller:stop()
        if not poller:is_closing() then
          poller:close()
        end
        poller = nil
      end
    end,
    desc = "Stop the Windows input method watcher",
  })
end

return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function(_, opts)
      start_watcher()

      opts.sections = opts.sections or {}
      opts.sections.lualine_x = opts.sections.lualine_x or {}

      table.insert(opts.sections.lualine_x, 1, {
        function()
          return labels[current_id] or ""
        end,
        cond = function()
          return labels[current_id] ~= nil
        end,
        color = { fg = "#e0af68", gui = "bold" },
        padding = { left = 1, right = 1 },
      })
    end,
  },
}
