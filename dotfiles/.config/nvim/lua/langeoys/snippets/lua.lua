local ls = require("luasnip")

local s = ls.s
local ms = ls.multi_snippet
local fmt = require("luasnip.extras.fmt").fmt
local i = ls.insert_node
local r = require("luasnip.extras").rep
local f = ls.function_node

-- Type classname, and convert parameter to lower case for first letter
local toParameter = function(index)
  return f(function(arg)
    return arg[1][1] .. "_group"
  end, { index })
end

return {
  s(
    "autocmd",
    fmt(
      [[
                local {} = vim.api.nvim_create_augroup('{}', {{ clear = true }})
                vim.api.nvim_create_autocmd('{}', {{
                    callback = function()
                        {}
                    end,
                    group = {},
                    pattern = '*',
                }})
            ]],
      -- { r(2), i(2), i(3), i(4), r(2) }
      { toParameter(1), i(1), i(2), i(3), toParameter(1) }
    )
  ),
  ms({
    common = { snippetType = "autosnippet" },
    {
      trig = "if ",
      condition = function()
        local ignored_nodes = { "string_fragment", "block_comment", "line_comment" }

        local pos = vim.api.nvim_win_get_cursor(0)
        -- Use one column to the left of the cursor to avoid a "chunk" node
        -- type. Not sure what it is, but it seems to be at the end of lines in
        -- some cases.
        local row, col = pos[1] - 1, pos[2] - 1

        local node_type = vim.treesitter
          .get_node({
            pos = { row, col },
          })
          :type()
        P(node_type)

        return not vim.tbl_contains(ignored_nodes, node_type)
      end,
    },
  }, {
    unpack(fmt(
      [[
  if {} then 
    {} 
  end
  ]],
      { i(1), i(2) }
    )),
  }),
}
