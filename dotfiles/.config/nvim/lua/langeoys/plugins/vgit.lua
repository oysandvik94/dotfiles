return {
  'tanvirtin/vgit.nvim',
  enabled = false,
  branch = 'v1.0.x',
  -- or               , tag = 'v1.0.2',
  dependencies = { 'nvim-lua/plenary.nvim', 'nvim-tree/nvim-web-devicons' },
  -- Lazy loading on 'VimEnter' event is necessary.
  event = 'VimEnter',
  config = function()
    local vgit = require("vgit")
    vgit.setup({
      settings = {

        scene = {
          keymaps = {
            quit = "q"
          }
        }
      }
    })
    vim.keymap.set('n', '[c', function() require('vgit').hunk_up() end, {})
    vim.keymap.set('n', ']c', function() require('vgit').hunk_down() end, {})
    vim.keymap.set('n', '<leader>cs', function() require('vgit').buffer_hunk_stage() end, {})
    vim.keymap.set('n', '<leader>cr', function() require('vgit').buffer_hunk_reset() end, {})
    vim.keymap.set('n', '<leader>cp', function() require('vgit').buffer_hunk_preview() end, {})
    vim.keymap.set('n', '<leader>cb', function() require('vgit').buffer_blame_preview() end, {})
    -- vim.keymap.set('n', '<leader>cf', function() require('vgit').buffer_diff_preview() end, {})
    vim.keymap.set('n', '<leader>ch', function() require('vgit').buffer_history_preview() end, {})
    vim.keymap.set('n', '<leader>cd', function() require('vgit').project_diff_preview() end, {})
    vim.keymap.set('n', '<leader>cx', function() require('vgit').toggle_diff_preference() end, {})
  end,
}
