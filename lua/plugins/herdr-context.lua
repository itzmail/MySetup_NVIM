return {
  "itzmail/herdr-watch.nvim",
  dir = vim.fn.expand("~/.config/nvim/ref/herdr-context.nvim"),
  enabled = false, -- disabled; set true (or remove) to re-enable
  cond = vim.env.HERDR_ENV == "1",
  lazy = false, -- keeps :checkhealth herdr-watch discoverable before the first mapping
  opts = {},
  keys = {
    {
      "<leader>ac",
      function()
        require("herdr-watch").compose()
      end,
      mode = { "n", "v" },
      desc = "Compose Herdr Context",
    },
    {
      "<leader>ap",
      function()
        require("herdr-watch").prompt()
      end,
      mode = { "n", "v" },
      desc = "Prompt Herdr with Code Context",
    },
    {
      "<leader>ay",
      function()
        require("herdr-watch").reference()
      end,
      mode = { "n", "v" },
      desc = "Send Reference to Herdr Agent",
    },
    {
      "<leader>aY",
      function()
        require("herdr-watch").send()
      end,
      mode = { "n", "v" },
      desc = "Send Context to Herdr Agent",
    },
    {
      "<leader>ad",
      function()
        require("herdr-watch").diagnostics()
      end,
      mode = { "n", "v" },
      desc = "Send Diagnostics to Herdr Agent",
    },
    {
      "<leader>at",
      function()
        require("herdr-watch").select_target()
      end,
      desc = "Select Herdr Agent",
    },
    {
      "<leader>aa",
      function()
        require("herdr-watch").agents()
      end,
      desc = "Toggle Herdr Agents",
    },
    {
      "<leader>ar",
      function()
        require("herdr-watch").refresh()
      end,
      desc = "Refresh Herdr Agents",
    },
    {
      "<leader>aw",
      function()
        require("herdr-watch").cursor_dashboard()
      end,
      desc = "Toggle Herdr Cursor Dashboard",
    },
  },
}
