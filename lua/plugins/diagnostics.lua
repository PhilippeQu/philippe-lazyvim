return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        -- Keep compact end-of-line diagnostics away from the cursor.
        virtual_text = {
          current_line = false,
        },
        -- Show the full diagnostic below the line being inspected.
        virtual_lines = {
          current_line = true,
          overflow = "wrap",
        },
      },
    },
  },
}
