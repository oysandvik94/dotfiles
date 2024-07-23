local ls = require("luasnip")

local s = ls.s
local fmt = require("luasnip.extras.fmt").fmt
local i = ls.insert_node
local rep = require("luasnip.extras").rep
local f = ls.function_node
local t = ls.text_node

-- Get classname from treesitter
local getClassName = function()
	return f(function()
		local parser = vim.treesitter.get_parser(0)
		local tree = parser:parse()[1]
		local query = vim.treesitter.query.parse("java", "(class_declaration (identifier) @name)")

		local class_name
		for id, node, metadata in query:iter_captures(tree:root(), 0) do
			local type_name = query.captures[id] -- name of the capture in the query
			if type_name == "name" then
				class_name = vim.treesitter.get_node_text(node, 0, { metadata = metadata })
			end
		end

		return class_name
	end)
end

-- Type classname, and convert parameter to lower case for first letter
local toParameter = function(index)
	return f(function(arg)
		return string.lower(string.sub(arg[1][1], 1, 1)) .. string.sub(arg[1][1], 2)
	end, { index })
end

local function get_package_name()
	local file_path = vim.fn.expand("%:p")
	local package_path = file_path:match("src/main/java/(.*)/.*%.java$")
	if package_path then
		return package_path:gsub("/", ".")
	end
	return ""
end

local function package_declaration()
	return f(function()
		local package_name = get_package_name()
		if package_name ~= "" then
			return { "package " .. package_name .. ";", "", "" }
		end
		return {}
	end, {})
end

-- Function to get the filename as the type name
local function type_name()
	return f(function()
		return vim.fn.expand("%:t:r")
	end, {})
end

return {
	s("logger", fmt("Logger logger = LoggerFactory.getLogger({}.class);", { getClassName() })),
	s("aw", fmt("private final {} {};", { i(1), toParameter(1) })),

	s("class", {
		package_declaration(),
		t({ "public class " }),
		type_name(),
		t({ " {", "" }),
		t({ "    " }),
		i(0),
		t({ "", "}" }),
	}),

	s("interface", {
		package_declaration(),
		t({ "public interface " }),
		type_name(),
		t({ " {", "" }),
		t({ "    " }),
		i(0),
		t({ "", "}" }),
	}),

	s("record", {
		package_declaration(),
		t({ "public record " }),
		type_name(),
		t("("),
		i(0),
		t({ ") { }" }),
	}),

	s("enum", {
		package_declaration(),
		t({ "public enum " }),
		type_name(),
		t({ " {", "" }),
		t({ "    " }),
		i(0),
		t({ "", "}" }),
	}),
}
