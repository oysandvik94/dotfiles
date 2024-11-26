return {
  {
    "echasnovski/mini.ai",
    version = false,
    config = function()
      require("mini.ai").setup()
    end,
  },
  {
    "echasnovski/mini.test",
    version = false,
    config = function()
      require("mini.test").setup()
    end,
  },
}
