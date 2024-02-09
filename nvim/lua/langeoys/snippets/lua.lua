local ls = require("luasnip")

local s = ls.s
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
}
