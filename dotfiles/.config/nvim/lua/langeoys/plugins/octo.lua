return {
  'pwntester/octo.nvim',
  requires = {
    'nvim-lua/plenary.nvim',
    'folke/snacks.nvim',
    'nvim-tree/nvim-web-devicons',
  },
  config = function()
    require "octo".setup({
      picker = "snacks",
      use_local_fs = true
    })
  end
}
