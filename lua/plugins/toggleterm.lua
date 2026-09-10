-- Floating sub-apps (lazygit / lazydocker) as named toggleterm terminals.
-- hidden = true: not part of the numbered toggle-term list; toggle-able anytime.
local function toggle_subapp(id, cmd, name)
  local M = require("toggleterm.terminal")
  local term = M.get(id, true)
  if not term then
    term = M.Terminal:new({
      cmd = cmd,
      direction = "float",
      hidden = true,
      id = id,
      display_name = name,
      close_on_exit = true,
      dir = vim.fn.expand("%:p:h"),
    })
  end
  term.dir = vim.fn.expand("%:p:h")
  term:toggle()
end

local function format_term_desc(term)
  local folder = term.dir and vim.fn.fnamemodify(term.dir, ":p:h:t") or "terminal"
  local name = term.display_name or folder
  local full_dir = term.dir and vim.fn.fnamemodify(term.dir, ":~") or ""
  local state = term:is_open() and "visible" or "hidden"
  return string.format("#%d: %s (%s) [%s]", term.id, name, full_dir ~= "" and full_dir or ".", state)
end

return {
  "akinsho/toggleterm.nvim",
  version = "*",
  cmd = { "ToggleTerm", "TermExec" },
  keys = {
    { "<leader>ft", '<Cmd>execute v:count . "ToggleTerm"<CR>', desc = "Toggle Terminal [count]" },
    {
      "<leader>fT",
      function()
        local count = require("toggleterm.terminal").get_all(true)
        vim.cmd((#count + 1) .. "ToggleTerm")
      end,
      desc = "New Terminal",
    },
    { "<leader>fv", "<cmd>ToggleTerm direction=vertical<cr>", desc = "Toggle Terminal (vertical)" },
    { [[<C-\>]], "<cmd>ToggleTerm<cr>", desc = "Toggle Terminal", mode = { "n", "t" } },
    { "<leader>fz", "<cmd>ZoomToggle<cr>", desc = "Zoom Window", mode = { "n", "t" } },
    { "<leader>j", "<cmd>ToggleTermToggleAll<cr>", desc = "Toggle/Close Terminal Pane", mode = { "n", "t" } },
    { "<leader>fq", "<cmd>ToggleTermToggleAll<cr>", desc = "Toggle Terminal All", mode = { "n", "t" } },
    {
      "<leader>fr",
      function()
        local term = require("toggleterm.terminal").get_focused()
        if not term then
          vim.notify("No focused terminal to rename", vim.log.levels.WARN)
          return
        end
        local folder = term.dir and vim.fn.fnamemodify(term.dir, ":p:h:t") or ""
        vim.ui.input(
          { prompt = "Rename Terminal #" .. term.id .. ": ", default = term.display_name or folder },
          function(input)
            if input and #input > 0 then
              term.display_name = input
              vim.notify("Terminal #" .. term.id .. " renamed to: " .. input, vim.log.levels.INFO)
            end
          end
        )
      end,
      desc = "Rename Terminal",
      mode = { "n", "t" },
    },
    {
      "<leader>fk",
      function()
        local count = vim.v.count
        local Terminal = require("toggleterm.terminal")

        if count > 0 then
          local term = Terminal.get(count, true)
          if term then
            term:shutdown()
            vim.notify("Killed Terminal #" .. count, vim.log.levels.INFO)
          else
            vim.notify("Terminal #" .. count .. " not found", vim.log.levels.WARN)
          end
          return
        end

        local focused = Terminal.get_focused()
        if focused then
          focused:shutdown()
          vim.notify("Killed Terminal #" .. focused.id, vim.log.levels.INFO)
          return
        end

        local terms = Terminal.get_all(true)
        if #terms == 0 then
          vim.notify("No active terminals", vim.log.levels.INFO)
          return
        end

        vim.ui.select(terms, {
          prompt = "Select Terminal to Kill:",
          format_item = format_term_desc,
        }, function(choice)
          if choice then
            choice:shutdown()
            vim.notify("Killed Terminal #" .. choice.id, vim.log.levels.INFO)
          end
        end)
      end,
      desc = "Kill Terminal [count/picker]",
      mode = { "n", "t" },
    },
    {
      "<leader>fK",
      function()
        local terms = require("toggleterm.terminal").get_all(true)
        if #terms == 0 then
          vim.notify("No active terminals", vim.log.levels.INFO)
          return
        end
        for _, term in ipairs(terms) do
          term:shutdown()
        end
        vim.notify("Killed all terminals (" .. #terms .. ")", vim.log.levels.INFO)
      end,
      desc = "Kill All Terminals",
      mode = { "n", "t" },
    },
    { "<leader>gg", function() toggle_subapp(90, "lazygit", "lazygit") end, desc = "Lazygit" },
    { "<leader>fd", function() toggle_subapp(91, "lazydocker", "lazydocker") end, desc = "Lazydocker" },
    {
      "<leader>fi",
      function()
        local terms = require("toggleterm.terminal").get_all(true)
        if #terms == 0 then
          vim.notify("No active terminals", vim.log.levels.INFO)
          return
        end
        local lines = {}
        for _, term in ipairs(terms) do
          table.insert(lines, format_term_desc(term))
        end
        vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "Active Terminals" })
      end,
      desc = "Terminal Status",
    },
  },
  opts = {
    name_formatter = function(term)
      local folder = term.dir and vim.fn.fnamemodify(term.dir, ":p:h:t") or "terminal"
      return term.display_name or folder
    end,
    size = function(term)
      if term.direction == "horizontal" then
        return math.floor(vim.o.lines * 0.35)
      elseif term.direction == "vertical" then
        return math.floor(vim.o.columns * 0.4)
      end
    end,
    direction = "horizontal",
    persist_size = true,
    close_on_exit = true,
    on_open = function(term)
      if term.window and vim.api.nvim_win_is_valid(term.window) then
        vim.wo[term.window].winfixbuf = true
        if term.direction == "horizontal" then
          vim.wo[term.window].winfixheight = true
        elseif term.direction == "vertical" then
          vim.wo[term.window].winfixwidth = true
        end
      end
    end,
  },
  config = function(_, opts)
    require("toggleterm").setup(opts)

    local zoomed = false
    local restore_cmd
    vim.api.nvim_create_user_command("ZoomToggle", function()
      if zoomed then
        vim.cmd(restore_cmd)
      else
        restore_cmd = vim.fn.winrestcmd()
        vim.cmd.wincmd("_")
        vim.cmd.wincmd("|")
      end
      zoomed = not zoomed
    end, {})

    vim.api.nvim_create_autocmd("TermOpen", {
      pattern = "term://*toggleterm#*",
      callback = function(event)
        local map_opts = { buffer = event.buf }
        -- Sub-app floats (lazygit/lazydocker, id >= 90) own <esc>:
        -- let them handle it; leave terminal mode with jk instead.
        local id = tonumber(event.match:match("toggleterm#(%d+)"))
        if not id or id < 90 then
          vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], map_opts)
        end
        vim.keymap.set("t", "jk", [[<C-\><C-n>]], map_opts)
        vim.wo.winfixbuf = true
        vim.wo.winfixheight = true
      end,
    })
  end,
}
