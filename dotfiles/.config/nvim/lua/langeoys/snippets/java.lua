local ls = require("luasnip")

local s = ls.s
local fmt = require("luasnip.extras.fmt").fmt
local i = ls.insert_node
local rep = require("luasnip.extras").rep
local f = ls.function_node

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

return {
    s("logger", fmt("Logger logger = LoggerFactory.getLogger({}.class);", { getClassName() })),
    s('aw', fmt(
        "private final {} {};",
        { i(1), toParameter(1) }
    ))
}
