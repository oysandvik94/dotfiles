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

    -- Consider only the branch segment after the last slash (if any)
    local branch_suffix = branch:match("([^/]+)$") or branch

    -- Extract numeric portion and build SECURITYSOLUTIONS ticket id
    local jira_number = branch_suffix:match("(%d+)")

    if jira_number and jira_number ~= "" then
      return "SECURITYSOLUTIONS-" .. jira_number .. ": "
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
