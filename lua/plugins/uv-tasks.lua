local function uv_project_root(path)
  local root = vim.fs.root(path, "uv.lock")
  if not root then
    return nil
  end
  if vim.fn.filereadable(root .. "/pyproject.toml") == 0 then
    return nil
  end
  local normalized_path = vim.fs.normalize(path):gsub("\\", "/")
  local normalized_root = vim.fs.normalize(root):gsub("\\", "/") .. "/"
  if normalized_path:sub(1, #normalized_root) ~= normalized_root then
    return nil
  end

  return root
end

local function current_uv_project_root()
  local file = vim.api.nvim_buf_get_name(0)
  if file ~= "" then
    local root = uv_project_root(file)
    if root then
      return root
    end
  end

  local root = vim.fs.root(vim.fn.getcwd(), "uv.lock")
  if root and vim.fn.filereadable(root .. "/pyproject.toml") == 1 then
    return root
  end

  return nil
end

local function python_module_name(file, root)
  local normalized_file = vim.fs.normalize(file):gsub("\\", "/")
  local src_root = vim.fs.normalize(root .. "/src"):gsub("\\", "/") .. "/"

  if normalized_file:sub(1, #src_root) ~= src_root then
    return nil
  end
  if normalized_file:sub(-3) ~= ".py" then
    return nil
  end

  local module = normalized_file:sub(#src_root + 1, #normalized_file - 3)
  module = module:gsub("/", ".")
  if module:sub(-9) == ".__init__" then
    module = module:sub(1, -10)
  end
  return module
end

local function uv_buffer_task()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" or file:sub(-3) ~= ".py" then
    vim.notify("Current buffer is not a Python file.", vim.log.levels.WARN)
    return nil
  end

  local root = uv_project_root(file)
  if not root then
    vim.notify("Current buffer is not inside a uv project.", vim.log.levels.WARN)
    return nil
  end

  local args = { "run", "python" }
  local module = python_module_name(file, root)
  if module then
    vim.list_extend(args, { "-m", module })
  else
    table.insert(args, file)
  end

  return {
    name = " uv run current buffer",
    cmd = "uv",
    args = args,
    cwd = root,
    env = {
      UV_CACHE_DIR = ".uv-cache",
    },
    strategy = {
      "jobstart",
      use_terminal = true,
    },
    components = { "default" },
  }
end

local function uv_pytest_task()
  local root = current_uv_project_root()
  if not root then
    vim.notify("Current buffer or cwd is not inside a uv project.", vim.log.levels.WARN)
    return nil
  end

  return {
    name = " uv run pytest",
    cmd = "uv",
    args = { "run", "pytest" },
    cwd = root,
    env = {
      UV_CACHE_DIR = ".uv-cache",
    },
    strategy = {
      "jobstart",
      use_terminal = true,
    },
    components = { "default" },
  }
end

local function run_uv_buffer()
  local task_spec = uv_buffer_task()
  if not task_spec then
    return
  end

  local overseer = require("overseer")
  local task = overseer.new_task(task_spec)
  task:start()
  overseer.open({ enter = false })
end

local function run_uv_pytest()
  local task_spec = uv_pytest_task()
  if not task_spec then
    return
  end

  local overseer = require("overseer")
  local task = overseer.new_task(task_spec)
  task:start()
  overseer.open({ enter = false })
end

return {
  {
    "stevearc/overseer.nvim",
    cmd = {
      "OverseerRun",
      "OverseerToggle",
      "OverseerQuickAction",
      "UvRunBuffer",
      "UvPytest",
    },
    keys = {
      {
        "<leader>ru",
        "<cmd>UvRunBuffer<cr>",
        desc = " Run current buffer with uv",
      },
      {
        "<leader>rp",
        "<cmd>UvPytest<cr>",
        desc = " Run pytest with uv",
      },
    },
    opts = {},
    config = function(_, opts)
      local overseer = require("overseer")
      overseer.setup(opts)

      overseer.register_template({
        name = " uv: run current buffer",
        builder = uv_buffer_task,
        condition = {
          callback = function()
            local file = vim.api.nvim_buf_get_name(0)
            return file ~= ""
              and file:sub(-3) == ".py"
              and uv_project_root(file) ~= nil
          end,
        },
      })

      overseer.register_template({
        name = " uv: pytest",
        builder = uv_pytest_task,
        condition = {
          callback = function()
            return current_uv_project_root() ~= nil
          end,
        },
      })

      vim.api.nvim_create_user_command("UvRunBuffer", run_uv_buffer, {
        desc = " Run current Python buffer with uv",
      })

      vim.api.nvim_create_user_command("UvPytest", run_uv_pytest, {
        desc = " Run pytest with uv",
      })
    end,
  },
}