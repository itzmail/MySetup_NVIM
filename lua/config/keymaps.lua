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
