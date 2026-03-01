local ok, jdtls = pcall(require, "jdtls")
if not ok then return end

local jdtls_path = vim.fn.stdpath("data") .. "/mason/packages/jdtls"

local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
local workspace_dir = vim.fn.stdpath("data") .. "/jdtls-workspaces/" .. project_name

local config = {
	cmd = {
		"java",
		"-Declipse.application=org.eclipse.jdt.ls.core.id1",
		"-Dosgi.bundles.defaultStartLevel=4",
		"-Declipse.product=org.eclipse.jdt.ls.core.product",
		"-Dlog.level=ALL",
		"-Xmx4g",
		"--add-modules=ALL-SYSTEM",
		"--add-opens", "java.base/java.util=ALL-UNNAMED",
		"--add-opens", "java.base/java.lang=ALL-UNNAMED",
		"-jar", vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar"),
		"-configuration", jdtls_path .. "/config_mac",
		"-data", workspace_dir,
	},
	root_dir = require("jdtls.setup").find_root({
		".git", "mvnw", "gradlew", "pom.xml", "build.gradle"
	}) or vim.fn.expand("%:p:h"),
	settings = {
		java = {
			configuration = {
				runtimes = {
					{ name = "JavaSE-21", path = "/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home" },
				},
			},
			maven = { downloadSources = true },
			gradle = { enabled = true },
			import = {
				gradle = { enabled = true },
				maven  = { enabled = true },
			},
		},
	},
	capabilities = require("blink.cmp").get_lsp_capabilities(),
	on_attach = function(client, bufnr)
		local map = function(keys, func, desc)
			vim.keymap.set("n", keys, func, { buffer = bufnr, desc = "Java: " .. desc })
		end
		map("gd", vim.lsp.buf.definition, "Go to Definition")
		map("K", vim.lsp.buf.hover, "Hover Docs")
		map("<leader>ca", vim.lsp.buf.code_action, "Code Action")
		map("<leader>rn", vim.lsp.buf.rename, "Rename")
		map("gr", vim.lsp.buf.references, "References")
		map("<leader>ji", jdtls.organize_imports, "Organize Imports")
		map("<leader>jv", jdtls.extract_variable, "Extract Variable")
		map("<leader>jm", jdtls.extract_method, "Extract Method")
		map("<leader>jc", jdtls.compile, "Compile Project")
	end,
}

jdtls.start_or_attach(config)
