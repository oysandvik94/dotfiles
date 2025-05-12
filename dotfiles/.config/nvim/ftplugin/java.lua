local jdtls_install = vim.fn.expand("$MASON/packages/jdtls")
local lombok_path = jdtls_install .. "/lombok.jar"

local function jdtls_on_attach(client, bufnr)
	vim.api.nvim_create_autocmd({ "BufWritePost", "LspAttach" }, {
		pattern = { "*.java" },
		callback = function()
			local _, _ = pcall(vim.lsp.codelens.refresh)
		end,
	})

	local opts = { buffer = bufnr }
	vim.keymap.set("n", "<leader>lo", "<cmd>lua require('jdtls').organize_imports()<cr>", opts)
	vim.keymap.set("n", "<leader>lev", "<cmd>lua require('jdtls').extract_variable()<cr>", opts)
	vim.keymap.set("x", "<leader>lev", "<esc><cmd>lua require('jdtls').extract_variable(true)<cr>", opts)
	vim.keymap.set("n", "<leader>lec", "<cmd>lua require('jdtls').extract_constant()<cr>", opts)
	vim.keymap.set("x", "<leader>lec", "<esc><cmd>lua require('jdtls').extract_constant(true)<cr>", opts)
	vim.keymap.set("x", "<leader>lem", "<esc><Cmd>lua require('jdtls').extract_method(true)<cr>", opts)

	require("langeoys.utils.lsp").on_attach(client, bufnr)
end

local function get_platform_config()
	if vim.fn.has("mac") == 1 then
		return jdtls_install .. "/config_mac"
	elseif vim.fn.has("unix") == 1 then
		return jdtls_install .. "/config_linux"
	elseif vim.fn.has("win32") == 1 then
		return jdtls_install .. "/config_win"
	end
end

local function get_data_dir()
	local jdtls_dir = vim.fn.stdpath("cache") .. "/nvim-jdtls"
	local data_dir = jdtls_dir .. "/" .. string.gsub(vim.fn.getcwd(), "/", "_")
	return data_dir
end
-- See `:help vim.lsp.start_client` for an overview of the supported `config` options.
local config = {
	-- The command that starts the language server
	-- See: https://github.com/eclipse/eclipse.jdt.ls#running-from-the-command-line
	on_attach = jdtls_on_attach,
	capabilities = require("blink.cmp").get_lsp_capabilities(),

	cmd = {
		-- 💀
		'java', -- or '/path/to/java17_or_newer/bin/java'
		-- depends on if `java` is in your $PATH env variable and if it points to the right version.

		-- "-Djava.import.generatesMetadataFilesAtProjectRoot=true",
		'-Declipse.application=org.eclipse.jdt.ls.core.id1',
		'-Dosgi.bundles.defaultStartLevel=4',
		'-Declipse.product=org.eclipse.jdt.ls.core.product',
		'-Dlog.protocol=true',
		'-Dlog.level=ALL',
		'-Xmx1g',
		"-XX:+UnlockExperimentalVMOptions",
		"-XX:+UseTransparentHugePages",
		"-XX:+AlwaysPreTouch",
		"-javaagent:" .. lombok_path,
		"-Xmx12G",
		'--add-modules=ALL-SYSTEM',
		'--add-opens',
		'java.base/java.util=ALL-UNNAMED',
		'--add-opens',
		'java.base/java.lang=ALL-UNNAMED',

		-- 💀
		"-jar",
		vim.fn.glob(jdtls_install .. "/plugins/org.eclipse.equinox.launcher_*.jar"),
		-- ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^                                       ^^^^^^^^^^^^^^
		-- Must point to the                                                     Change this to
		-- eclipse.jdt.ls installation                                           the actual version


		-- 💀
		'-configuration',
		get_platform_config(),
		-- ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^        ^^^^^^
		-- Must point to the                      Change to one of `linux`, `win` or `mac`
		-- eclipse.jdt.ls installation            Depending on your system.


		-- 💀
		-- See `data directory configuration` section in the README
		'-data',
		get_data_dir(),
	},

	-- 💀
	-- This is the default if not provided, you can remove it. Or adjust as needed.
	-- One dedicated LSP server & client will be started per unique root_dir
	--
	-- vim.fs.root requires Neovim 0.10.
	-- If you're using an earlier version, use: require('jdtls.setup').find_root({'.git', 'mvnw', 'gradlew'}),
	root_dir = vim.fs.root(0, { ".git", "mvnw", "gradlew" }),

	-- Here you can configure eclipse.jdt.ls specific settings
	-- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
	-- for a list of options
	-- handlers = {
	-- 	["$/progress"] = function(_, result, ctx) end,
	-- },
	settings = {
		java = {
			autobuild = {
				enabled = false
			},
			-- jdt = {
			-- 	ls = {
			-- 		javac = {
			-- 			enabled = "on",
			-- 		}
			-- 	}
			-- },
			eclipse = {
				downloadSources = true,
			},
			configuration = {
				updateBuildConfiguration = "interactive",
			},
			maven = {
				downloadSources = true,
			},
			signatureHelp = {
				enabled = true,
			},
			completion = {
				maxResults = 20,
				favoriteStaticMembers = {
					"org.hamcrest.MatcherAssert.assertThat",
					"org.hamcrest.Matchers.*",
					"org.hamcrest.CoreMatchers.*",
					"org.junit.jupiter.api.Assertions.*",
					"java.util.Objects.requireNonNull",
					"java.util.Objects.requireNonNullElse",
					"org.mockito.Mockito.*",
				},
				filteredTypes = {
					"com.sun.*",
					"io.micrometer.shaded.*",
					"java.awt.*",
					"jdk.*",
					"sun.*",
				},
				matchCase = "off",
				guessMethodArguments = "insertBestGuessedArguments",
			},
			inlayHints = {
				parameterNames = {
					enabled = "all", -- literals, all, none
				},
			},
			contentProvider = {
				preferred = "fernflower",
			},
			referencesCodeLens = {
				enabled = true,
			},
			implementationsCodeLens = {
				enabled = true
			}
		}
	},

	-- Language server `initializationOptions`
	-- You need to extend the `bundles` with paths to jar files
	-- if you want to use additional eclipse.jdt.ls plugins.
	--
	-- See https://github.com/mfussenegger/nvim-jdtls#java-debug-installation
	--
	-- If you don't plan on using the debugger or other eclipse.jdt.ls plugins you can remove this
	init_options = {
		bundles = {}
	},
}
-- This starts a new client & server,
-- or attaches to an existing client & server depending on the `root_dir`.
require('jdtls').start_or_attach(config)
