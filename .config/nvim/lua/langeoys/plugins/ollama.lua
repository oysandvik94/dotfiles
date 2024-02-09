local response_format = "Respond EXACTLY in this format:\n```$ftype\n<your code>\n```"
local generic = "Limit prose and be concise. "
return {
	"nomnivore/ollama.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},

	-- All the user commands added by the plugin
	cmd = { "Ollama", "OllamaModel", "OllamaServe", "OllamaServeStop" },

	keys = {
		-- Sample keybind for prompt menu. Note that the <c-u> is important for selections to work properly.
		{
			"<leader>oo",
			":<c-u>lua require('ollama').prompt()<cr>",
			desc = "ollama prompt",
			mode = { "n", "v" },
		},

		-- Sample keybind for direct prompting. Note that the <c-u> is important for selections to work properly.
		{
			"<leader>oG",
			":<c-u>lua require('ollama').prompt('Generate_Code')<cr>",
			desc = "ollama Generate Code",
			mode = { "n", "v" },
		},
	},

	opts = {
		-- model = "phind-codellama"
		model = "deepseek-coder:6.7b-instruct",
		-- model = "deepseek-coder"
		prompts = {
			Ask_About_Code = {
				prompt = "I have a question about this: $input\n\n " .. generic .. "Here is the code:\n```$ftype\n$sel```",
				input_label = "Q",
			},

			Explain_Code = {
				prompt = generic .. "Explain this code:\n```$ftype\n$sel\n```",
			},

			-- basically "no prompt"
			Raw = {
				prompt = "$input",
				input_label = ">",
				action = "display",
			},

			Simplify_Code = {
				prompt = "Simplify the following $ftype code so that it is both easier to read and understand. "
					.. response_format
					.. "\n\n```$ftype\n$sel```",
				action = "replace",
			},

			Modify_Code = {
				prompt = "Modify this $ftype code in the following way: $input\n\n"
					.. response_format
					.. "\n\n```$ftype\n$sel```",
				action = "replace",
			},

			Generate_Code = {
				prompt = "Generate $ftype code that does the following: $input\n\n" .. response_format,
				action = "insert",
			},
		},
	},
}
