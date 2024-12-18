return {
  "aaronik/treewalker.nvim",
  opts = {
    highlight = true -- Whether to briefly highlight the node after jumping to it
  },
  config = function()
    vim.api.nvim_set_keymap('n', '<leader><Down>', ':Treewalker Down<CR>', { noremap = true })
    vim.api.nvim_set_keymap('n', '<leader><Up>', ':Treewalker Up<CR>', { noremap = true })
    vim.api.nvim_set_keymap('n', '<leader><Left>', ':Treewalker Left<CR>', { noremap = true })
    vim.api.nvim_set_keymap('n', '<leader><Right>', ':Treewalker Right<CR>', { noremap = true })
  end
}
