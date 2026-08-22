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
    { "<leader>fq", "<cmd>ToggleTermToggleAll<cr>", desc = "Toggle Terminal All", mode = { "n", "t" } },
    {
      "<leader>fi",
      function()
        local terms = require("toggleterm.terminal").get_all(true)
        if #terms == 0 then
          vim.notify("No terminals", vim.log.levels.INFO)
          return
        end
        local lines = {}
        for _, term in ipairs(terms) do
          table.insert(lines, ("#%d: %s"):format(term.id, term:is_open() and "visible" or "hidden"))
        end
        vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "Terminals" })
      end,
      desc = "Terminal Status",
    },
  },
  opts = {
    direction = "horizontal",
    persist_size = true,
    close_on_exit = true,
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
        vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], map_opts)
        vim.keymap.set("t", "jk", [[<C-\><C-n>]], map_opts)
      end,
    })
  end,
}
