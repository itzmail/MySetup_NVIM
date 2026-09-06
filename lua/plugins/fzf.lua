local function get_target_editor_win()
  local cur_win = vim.api.nvim_get_current_win()
  local cur_buf = vim.api.nvim_win_get_buf(cur_win)
  if
    vim.bo[cur_buf].buftype ~= "terminal"
    and vim.bo[cur_buf].filetype ~= "toggleterm"
    and vim.bo[cur_buf].filetype ~= "neo-tree"
    and vim.bo[cur_buf].filetype ~= "Outline"
    and vim.bo[cur_buf].filetype ~= "trouble"
  then
    return cur_win
  end

  -- Check previous window
  local prev_win = vim.fn.win_getid(vim.fn.winnr("#"))
  if prev_win and prev_win ~= 0 and vim.api.nvim_win_is_valid(prev_win) then
    local pbuf = vim.api.nvim_win_get_buf(prev_win)
    if
      vim.bo[pbuf].buftype ~= "terminal"
      and vim.bo[pbuf].filetype ~= "toggleterm"
      and vim.bo[pbuf].filetype ~= "neo-tree"
      and vim.bo[pbuf].filetype ~= "Outline"
      and vim.bo[pbuf].filetype ~= "trouble"
    then
      return prev_win
    end
  end

  -- Find any normal non-floating window in current tab
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local conf = vim.api.nvim_win_get_config(win)
    if conf.relative == "" then
      local buf = vim.api.nvim_win_get_buf(win)
      if
        vim.bo[buf].buftype ~= "terminal"
        and vim.bo[buf].filetype ~= "toggleterm"
        and vim.bo[buf].filetype ~= "neo-tree"
        and vim.bo[buf].filetype ~= "Outline"
        and vim.bo[buf].filetype ~= "trouble"
      then
        return win
      end
    end
  end

  return nil
end

return {
  {
    "ibhagwan/fzf-lua",
    opts = function(_, opts)
      opts = opts or {}
      opts.actions = opts.actions or {}
      opts.actions.files = opts.actions.files or {}

      local fzf = require("fzf-lua")
      local default_file_edit = fzf.actions.file_edit_or_qf

      local function safe_file_edit(selected, o)
        local cur_buf = vim.api.nvim_get_current_buf()
        if vim.bo[cur_buf].buftype == "terminal" or vim.bo[cur_buf].filetype == "toggleterm" then
          local target = get_target_editor_win()
          if target and vim.api.nvim_win_is_valid(target) then
            vim.api.nvim_set_current_win(target)
          else
            vim.cmd("wincmd p")
          end
        end
        return default_file_edit(selected, o)
      end

      opts.actions.files["enter"] = safe_file_edit

      return opts
    end,
  },
}
