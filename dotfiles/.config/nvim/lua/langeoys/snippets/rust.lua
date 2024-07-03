local ls = require("luasnip")

local s = ls.s
local fmt = require("luasnip.extras.fmt").fmt
local i = ls.insert_node
local t = ls.text_node
local f = ls.function_node

return {
	s({ trig = "(%w+)lt", regTrig = true }, {
		f(function(_, snip)
			return snip.captures[1]
		end, {}),
		t("<'"),
		i(1),
		t(">"),
	}),
}
