-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local _catppuccin_flavour = "macchiato"

vim.keymap.set("n", "<leader>tt", function()
  _catppuccin_flavour = _catppuccin_flavour == "macchiato" and "latte" or "macchiato"
  vim.cmd.colorscheme("catppuccin-" .. _catppuccin_flavour)
  vim.notify("Theme: catppuccin-" .. _catppuccin_flavour)
end, { desc = "Toggle dark/light theme" })

local function copy_path_with_line(fmt)
  return function()
    local path = vim.fn.expand(fmt)
    local mode = vim.fn.mode()
    local suffix

    if mode == "v" or mode == "V" or mode == "\22" then
      local start_line = vim.fn.line("v")
      local end_line = vim.fn.line(".")
      if start_line > end_line then
        start_line, end_line = end_line, start_line
      end
      suffix = start_line == end_line and (":" .. start_line) or (":" .. start_line .. "-" .. end_line)
      vim.cmd("normal! \27") -- exit visual mode
    else
      suffix = ":" .. vim.fn.line(".")
    end

    local result = path .. suffix
    vim.fn.setreg("+", result)
    vim.notify("Copied: " .. result)
  end
end

vim.keymap.set({ "n", "v" }, "<leader>cp", copy_path_with_line("%:p"), { desc = "Copy Absolute Path:Line" })
vim.keymap.set({ "n", "v" }, "<leader>cP", copy_path_with_line("%:."), { desc = "Copy Relative Path:Line" })

vim.api.nvim_create_user_command("LspRestart", function()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    vim.notify("No active LSP clients attached to buffer", vim.log.levels.WARN)
    return
  end

  local names = {}
  for _, client in ipairs(clients) do
    table.insert(names, client.name)
    vim.lsp.stop_client(client.id, true)
  end

  vim.notify("Restarting LSP: " .. table.concat(names, ", "), vim.log.levels.INFO)

  vim.defer_fn(function()
    vim.cmd("edit")
  end, 300)
end, { desc = "Restart LSP clients attached to current buffer" })

vim.keymap.set("n", "<leader>cL", "<cmd>LspRestart<cr>", { desc = "Restart LSP" })
