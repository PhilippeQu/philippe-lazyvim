local MAX_VIRTUAL_LINES = 3
local MIN_MESSAGE_WIDTH = 24
local VIRTUAL_LINE_PADDING = 8

local function take_by_display_width(text, max_width)
  local low = 1
  local high = vim.fn.strchars(text)
  local count = 0

  while low <= high do
    local mid = math.floor((low + high) / 2)
    local chunk = vim.fn.strcharpart(text, 0, mid)
    if vim.fn.strdisplaywidth(chunk) <= max_width then
      count = mid
      low = mid + 1
    else
      high = mid - 1
    end
  end

  count = math.max(count, 1)
  return vim.fn.strcharpart(text, 0, count), count
end

local function message_width(diagnostic)
  local width
  local bufnr = diagnostic.bufnr
  local column_width = 0

  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    local line = vim.api.nvim_buf_get_lines(bufnr, diagnostic.lnum, diagnostic.lnum + 1, false)[1] or ""
    column_width = vim.fn.strdisplaywidth(line:sub(1, diagnostic.col))

    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_buf(win) == bufnr then
        local info = vim.fn.getwininfo(win)[1]
        local textoff = info and info.textoff or 0
        local available =
          vim.api.nvim_win_get_width(win) - textoff - column_width - VIRTUAL_LINE_PADDING
        width = width and math.min(width, available) or available
      end
    end
  end

  return math.max(width or vim.o.columns - VIRTUAL_LINE_PADDING, MIN_MESSAGE_WIDTH)
end

local function wrap_line(line, width)
  if line == "" then
    return { "" }
  end

  local indent = line:match("^%s*") or ""
  local content = line:sub(#indent + 1)
  local indent_width = vim.fn.strdisplaywidth(indent)
  if indent_width >= width - 4 then
    indent = ""
    indent_width = 0
  end

  local available = math.max(width - indent_width, 1)
  local wrapped = {}

  while content ~= "" do
    if vim.fn.strdisplaywidth(content) <= available then
      wrapped[#wrapped + 1] = indent .. content
      break
    end

    local chunk, count = take_by_display_width(content, available)
    local break_at = chunk:match("^.*()%s")
    if break_at and break_at > 1 then
      chunk = chunk:sub(1, break_at - 1)
      count = vim.fn.strchars(chunk)
    end

    wrapped[#wrapped + 1] = indent .. chunk:gsub("%s+$", "")
    content = vim.fn.strcharpart(content, count):gsub("^%s+", "")
  end

  return wrapped
end

local function truncate_last_line(line, width)
  local suffix = "..."
  while line ~= "" and vim.fn.strdisplaywidth(line .. suffix) > width do
    line = vim.fn.strcharpart(line, 0, vim.fn.strchars(line) - 1)
  end
  return line:gsub("%s+$", "") .. suffix
end

local function format_diagnostic(diagnostic)
  local message = diagnostic.message:gsub("\r\n", "\n"):gsub("\r", "\n")
  if diagnostic.code then
    message = ("%s: %s"):format(diagnostic.code, message)
  end

  local width = message_width(diagnostic)
  local lines = {}

  for _, line in ipairs(vim.split(message, "\n", { plain = true })) do
    vim.list_extend(lines, wrap_line(line, width))
  end

  if #lines > MAX_VIRTUAL_LINES then
    lines[MAX_VIRTUAL_LINES] = truncate_last_line(lines[MAX_VIRTUAL_LINES], width)
    for index = #lines, MAX_VIRTUAL_LINES + 1, -1 do
      lines[index] = nil
    end
  end

  return table.concat(lines, "\n")
end

return {
  {
    "neovim/nvim-lspconfig",
    init = function()
      local group = vim.api.nvim_create_augroup("diagnostic_virtual_lines_resize", { clear = true })
      vim.api.nvim_create_autocmd({ "VimResized", "WinResized" }, {
        group = group,
        callback = function()
          vim.schedule(function()
            local buffers = {}
            for _, win in ipairs(vim.api.nvim_list_wins()) do
              buffers[vim.api.nvim_win_get_buf(win)] = true
            end
            for bufnr in pairs(buffers) do
              if vim.api.nvim_buf_is_valid(bufnr) then
                vim.diagnostic.show(nil, bufnr)
              end
            end
          end)
        end,
      })
    end,
    opts = {
      diagnostics = {
        -- Keep compact end-of-line diagnostics away from the cursor.
        virtual_text = {
          current_line = false,
        },
        -- Show a wrapped, bounded preview below the line being inspected.
        virtual_lines = {
          current_line = true,
          format = format_diagnostic,
        },
      },
    },
  },
}
