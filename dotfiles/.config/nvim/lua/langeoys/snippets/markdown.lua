local ls = require("luasnip")

local s = ls.s
local fmt = require("luasnip.extras.fmt").fmt
local i = ls.insert_node
local rep = require("luasnip.extras").rep
local f = ls.function_node
local t = ls.text_node

return {
	s("link", fmt("[{}]({})", { i(1), i(2) })),
}
