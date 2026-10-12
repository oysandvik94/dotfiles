return {
  'JetBrains/intellij-lsp.nvim',
  dependencies = { 'mfussenegger/nvim-dap' }, -- optional: run and debug
  opts = {
    accept_eula = true,                       -- read EULA.txt in the downloaded bundle first
    jvm_args = { '-Xmx8g' }, -- -XX:CICompilerCount=4 tested: slower completion than the default 2
    -- let blink.cmp handle completion instead of the native menu
    autotrigger = false,
    completion_delay = 30,
    completeopt = false,
    enter_accepts_completion = false,
  },
}
