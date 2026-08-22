return {
  "sphamba/smear-cursor.nvim",
  event = "VeryLazy",

  opts = { -- Default  Range
    stiffness = 0.8, -- 0.6      [0, 1]
    trailing_stiffness = 0.6, -- 0.45     [0, 1]
    stiffness_insert_mode = 0.7, -- 0.5      [0, 1]
    trailing_stiffness_insert_mode = 0.7, -- 0.5      [0, 1]
    damping = 0.95, -- 0.85     [0, 1]
    damping_insert_mode = 0.95, -- 0.9      [0, 1]
    distance_stop_animating = 0.5, -- 0.1      > 0
  },
  config = function(_, opts)
    require("smear_cursor").setup(opts)

    Snacks.toggle({
      name = "Smear Cursor",
      get = function()
        return require("smear_cursor").enabled
      end,
      set = function(state)
        require("smear_cursor").enabled = state
      end,
    }):map("<leader>uM")
  end,
}
