local M = {}

M.go_to_error = function()
	local current_line, _ = unpack(vim.api.nvim_win_get_cursor(0))
	local diagnostics = vim.diagnostic.get(0, { lnum = (current_line - 1) })

	for _, diagnostic in ipairs(diagnostics) do
		local user_data = diagnostic.user_data
		if user_data.lsp and user_data.lsp.codeDescription and user_data.lsp.codeDescription.href then
			local url = user_data.lsp.codeDescription.href
			vim.ui.open(url)
			return
		end
	end
end

M.deprioritize_postfix = function(entry1, entry2)
	local kind1 = entry1:get_kind()
	local kind2 = entry2:get_kind()
	-- if one of them is nil, compare is pointless
	if kind1 ~= kind2 then
		-- 15 is text
		if kind1 == 15 then
			return false
		end
		if kind2 == 15 then
			return true
		end
	end
end

M.deprioritize_common_traits = function(entry1, entry2)
	local function is_common_trait(entry)
		local label_details = entry.completion_item.labelDetails
		if label_details == nil then
			return false
		end

		local label = label_details.detail

		if label == nil then
			return false
		end
		-- find `(as Trait)` in the label
		local trait = label:match("%(as ([^)]+)%)")
		if trait == nil then
			return false
		end
		return vim.iter({
			"Clone",
			"Copy",
			"Deref",
			"DerefMut",
			"Borrow",
			"BorrowMut",
			"Drop",
			"ToString",
			"ToOwned",
			"PartialEq",
			"PartialOrd",
			"AsRef",
			"AsMut",
			"From",
			"Into",
			"TryFrom",
			"TryInto",
			"Default",
		}):find(function(x)
			return x == trait
		end) ~= nil
	end
	local is_common_1 = is_common_trait(entry1)
	local is_common_2 = is_common_trait(entry2)
	if is_common_1 ~= is_common_2 then
		return not is_common_1
	end
end

M.deprioritize_borrow = function(entry1, entry2)
	local function has_borrow(entry)
		local label = entry.completion_item.detail
		if label == nil then
			return false
		end
		-- find `(use ...)` in the label
		return label:match("%(use %a+::borrow::Borrow") ~= nil
	end
	local use1 = has_borrow(entry1)
	local use2 = has_borrow(entry2)
	if use1 ~= use2 then
		return not use1
	end
end

M.deprioritize_deref = function(entry1, entry2)
	local function has_deref(entry)
		local label = entry.completion_item.detail
		if label == nil then
			return false
		end
		return label:match("Deref") ~= nil
	end
	local use1 = has_deref(entry1)
	local use2 = has_deref(entry2)
	if use1 ~= use2 then
		return not use1
	end
end

return M
