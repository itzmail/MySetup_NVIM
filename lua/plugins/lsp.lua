return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        lua_ls = {},
        gopls = {},
        vtsls = {},
        biome = {},
        svelte = {},
        marksman = {},
        kotlin_language_server = {
          on_attach = function(client, bufnr)
            -- Matikan documentHighlight penyebab crash -32603
            client.server_capabilities.documentHighlightProvider = false
          end,
        },
      },
    },
  },
}
