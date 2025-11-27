local ls = require("luasnip")

local s = ls.s
local f = ls.function_node
local i = ls.insert_node
local t = ls.text_node

-- Function to extract JIRA ticket from git branch
local function get_jira_ticket()
  return f(function()
    -- Get current git branch
    local handle = io.popen("git branch --show-current 2>/dev/null")
    local branch = handle:read("*a")
    handle:close()

    -- Remove trailing newline
    branch = branch:gsub("\n$", "")

    -- Extract JIRA ticket (everything before first underscore)
    local jira_ticket = branch:match("^([^_]+)")

    if jira_ticket and jira_ticket ~= "" then
      return jira_ticket .. ": "
    else
      return ""
    end
  end, {})
end

return {
  s("jira", {
    get_jira_ticket(),
    i(0)
  })
}
