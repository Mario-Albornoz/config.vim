local ok, jdtls = pcall(require, 'jdtls')
if not ok then return end

local jdtls_path = vim.fn.stdpath 'data' .. '/mason/packages/jdtls'
local is_windows = vim.fn.has 'win32' == 1
local is_mac = vim.fn.has 'mac' == 1

local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
local workspace_dir = vim.fn.stdpath 'data' .. '/jdtls-workspaces/' .. project_name

-- Lombok: use the correct platform-aware base path
local lombok_base = is_windows and vim.fn.expand '$USERPROFILE/.m2/repository/org/projectlombok/lombok'
  or vim.fn.expand '~/.m2/repository/org/projectlombok/lombok'

local lombok_jars = vim.fn.globpath(lombok_base, '*/lombok-*.jar', false, true)
table.sort(lombok_jars)
local lombok_jar = lombok_jars[#lombok_jars] -- last item after sort = highest version

-- Config dir: handle Windows, Mac, and Linux
local config_dir = is_windows and '/config_win' or (is_mac and '/config_mac' or '/config_linux')

-- Java home: prefer JAVA_HOME env var, fall back to hardcoded paths
local java_home
if vim.fn.expand '$JAVA_HOME' ~= '' and vim.fn.expand '$JAVA_HOME' ~= '$JAVA_HOME' then
  java_home = vim.fn.expand '$JAVA_HOME'
elseif is_windows then
  java_home = 'C:/Users/mario.albornoz/.jdks/azul-21.0.7'
else
  java_home = '/home/user/.sdkman/candidates/java/21-tem'
end

-- Build cmd, conditionally including lombok agent only if jar was found
local cmd = {
  'java',
  '-Declipse.application=org.eclipse.jdt.ls.core.id1',
  '-Dosgi.bundles.defaultStartLevel=4',
  '-Declipse.product=org.eclipse.jdt.ls.core.product',
  '-Dlog.level=ALL',
  '-Xmx4g',
  '--add-modules=ALL-SYSTEM',
  '--add-opens',
  'java.base/java.util=ALL-UNNAMED',
  '--add-opens',
  'java.base/java.lang=ALL-UNNAMED',
  '-jar',
  vim.fn.glob(jdtls_path .. '/plugins/org.eclipse.equinox.launcher_*.jar'),
  '-configuration',
  jdtls_path .. config_dir,
  '-data',
  workspace_dir,
}

-- Safely inject lombok javaagent if jar exists
if lombok_jar and lombok_jar ~= '' then
  table.insert(cmd, 6, '-javaagent:' .. lombok_jar)
else
  vim.notify('[jdtls] Lombok jar not found — Lombok support disabled.', vim.log.levels.WARN)
end

local config = {
  cmd = cmd,

  root_dir = require('jdtls.setup').find_root {
    '.git',
    'mvnw',
    'gradlew',
    'pom.xml',
    'build.gradle',
  } or vim.fn.expand '%:p:h',

  settings = {
    java = {
      configuration = {
        runtimes = {
          { name = 'JavaSE-21', path = java_home },
        },
      },
      maven = { downloadSources = true },
      gradle = { enabled = true },
      import = {
        gradle = { enabled = true },
        maven = { enabled = true },
      },
    },
  },

  capabilities = require('blink.cmp').get_lsp_capabilities(),

  on_attach = function(_client, bufnr)
    local map = function(keys, func, desc) vim.keymap.set('n', keys, func, { buffer = bufnr, desc = 'Java: ' .. desc }) end

    map('gd', vim.lsp.buf.definition, 'Go to Definition')
    map('K', vim.lsp.buf.hover, 'Hover Docs')
    map('<leader>ca', vim.lsp.buf.code_action, 'Code Action')
    map('<leader>rn', vim.lsp.buf.rename, 'Rename')
    map('gr', vim.lsp.buf.references, 'References')
    map('<leader>ji', jdtls.organize_imports, 'Organize Imports')
    map('<leader>jv', jdtls.extract_variable, 'Extract Variable')
    map('<leader>jm', jdtls.extract_method, 'Extract Method')
    map('<leader>jc', jdtls.compile, 'Compile Project')
  end,
}

jdtls.start_or_attach(config)
