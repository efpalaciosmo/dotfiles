-- LSP setup using Neovim 0.12's vim.lsp.config() / vim.lsp.enable().
-- nvim-lspconfig contributes pre-baked configs via its lsp/<name>.lua files;
-- the entries below override or extend them per-server.
-- Servers must be on $PATH; missing ones are skipped at the bottom of this file.

-- ============================================================================
-- Capabilities & defaults (applied to every server via vim.lsp.config('*')).
-- ============================================================================

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true
capabilities.textDocument.completion.completionItem.resolveSupport = {
    properties = { "documentation", "detail", "additionalTextEdits" },
}
capabilities.textDocument.foldingRange = {
    dynamicRegistration = false,
    lineFoldingOnly = true,
}

-- Merge blink.cmp's enhanced capabilities (snippet expansion, resolve support, etc).
local ok_blink, blink = pcall(require, "blink.cmp")
if ok_blink then
    capabilities = blink.get_lsp_capabilities(capabilities)
end

vim.lsp.config("*", {
    capabilities = capabilities,
    root_markers = { ".git", ".hg", ".svn" },
})

-- ============================================================================
-- Per-server configs. Add/remove freely; only servers whose binary is found
-- on $PATH are actually enabled below.
-- ============================================================================

vim.lsp.config("lua_ls", {
    cmd = { "lua-language-server" },
    filetypes = { "lua" },
    root_markers = { ".luarc.json", ".luarc.jsonc", ".stylua.toml", "stylua.toml", ".git" },
    settings = {
        Lua = {
            runtime = { version = "LuaJIT" },
            workspace = {
                checkThirdParty = false,
                library = {
                    vim.env.VIMRUNTIME,
                    "${3rd}/luv/library",
                },
            },
            diagnostics = { globals = { "vim" } },
            telemetry = { enable = false },
            hint = { enable = true },
        },
    },
})

vim.lsp.config("basedpyright", {
    cmd = { "basedpyright-langserver", "--stdio" },
    filetypes = { "python" },
    root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", "Pipfile", ".git" },
    settings = {
        basedpyright = {
            disableOrganizeImports = true,
            analysis = {
                autoSearchPaths = true,
                autoImportCompletions = true,
                diagnosticMode = "openFilesOnly",
                enableTypeIgnoreComments = false,
                typeCheckingMode = "basic",
                useLibraryCodeForTypes = true,
                diagnosticSeverityOverrides = {
                    reportArgumentType = "none",
                    reportAssignmentType = "none",
                    reportGeneralTypeIssues = "none",
                    reportUnknownMemberType = "none",
                },
            },
        },
    },
})

vim.lsp.config("ruff", {
    cmd = { "ruff", "server" },
    filetypes = { "python" },
    root_markers = { "pyproject.toml", "ruff.toml", ".ruff.toml", ".git" },
    on_attach = function(client)
        -- Let basedpyright own Python hover/type information; ruff handles lint/format/code actions.
        client.server_capabilities.hoverProvider = false
    end,
})

vim.lsp.config("vtsls", {
    cmd = { "vtsls", "--stdio" },
    filetypes = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "vue",
    },
    root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
})

vim.lsp.config("clangd", {
    cmd = { "clangd", "--background-index", "--clang-tidy", "--header-insertion=iwyu" },
    filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
    root_markers = { ".clangd", "compile_commands.json", "compile_flags.txt", "Makefile", ".git" },
})

vim.lsp.config("zls", {
    cmd = { "zls" },
    filetypes = { "zig", "zir" },
    root_markers = { "zls.json", "build.zig", ".git" },
    settings = {
        zls = {
            enable_inlay_hints = true,
            inlay_hints_show_variable_type_hints = true,
            inlay_hints_show_parameter_name = true,
            warn_style = true,
        },
    },
})

vim.lsp.config("rust_analyzer", {
    cmd = { "rust-analyzer" },
    filetypes = { "rust" },
    root_markers = { "Cargo.toml", ".git", "rust-project.json" },
    settings = {
        ["rust-analyzer"] = {
            cargo = { allFeatures = true },
            check = {
                command = "clippy",
            },
            inlayHints = {
                bindingModeHints = { enable = true },
                chainingHints = { enable = true },
                closingBraceHints = { enable = true, minLines = 5 },
                closureReturnTypeHints = { enable = "always" },
                lifetimeElisionHints = { enable = "always", useParameterNames = true },
                typeHints = { enable = true, hideNamedConstructor = false },
            },
            procMacro = { enable = true },
            imports = { granularity = { group = "module" } },
        },
    },
})

vim.lsp.config("julials", {
    cmd = { "julia-lsp" },
    filetypes = { "julia" },
    root_markers = { "Project.toml", "JuliaProject.toml", ".git" },
})

vim.lsp.config("bashls", {
    cmd = { "bash-language-server", "start" },
    filetypes = { "sh", "bash", "zsh" },
    root_markers = { ".git" },
})

vim.lsp.config("marksman", {
    cmd = { "marksman", "server" },
    filetypes = { "markdown", "markdown.mdx" },
    root_markers = { ".marksman.toml", ".git" },
})

vim.lsp.config("jsonls", {
    cmd = { "vscode-json-language-server", "--stdio" },
    filetypes = { "json", "jsonc" },
    root_markers = { ".git" },
})

vim.lsp.config("yamlls", {
    cmd = { "yaml-language-server", "--stdio" },
    filetypes = { "yaml", "yaml.docker-compose" },
    root_markers = { ".git" },
})

vim.lsp.config("html", {
    cmd = { "vscode-html-language-server", "--stdio" },
    filetypes = { "html" },
    root_markers = { "package.json", ".git" },
})

vim.lsp.config("cssls", {
    cmd = { "vscode-css-language-server", "--stdio" },
    filetypes = { "css", "scss", "less" },
    root_markers = { "package.json", ".git" },
})

vim.lsp.config("tailwindcss", {
    cmd = { "tailwindcss-language-server", "--stdio" },
    filetypes = {
        "html",
        "css",
        "scss",
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "vue",
        "svelte",
        "astro",
    },
    root_markers = {
        "tailwind.config.js",
        "tailwind.config.cjs",
        "tailwind.config.mjs",
        "tailwind.config.ts",
        ".git",
    },
})

-- ============================================================================
-- Enable servers whose first cmd entry is actually executable.
-- ============================================================================

local servers = {
    "lua_ls",
    -- python
    "basedpyright",
    "ruff",
    -- javascript / typescript
    "vtsls",
    -- c
    "clangd",
    -- zig
    "zls",
    -- rust
    "rust_analyzer",
    -- julia
    "julials",
    -- shell
    "bashls",
    -- markdown
    "marksman",
    -- web
    "html",
    "cssls",
    "tailwindcss",
    -- misc
    "jsonls",
    "yamlls",
}

local function enable_available_servers()
    for _, name in ipairs(servers) do
        local cfg = vim.lsp.config[name]
        if cfg and cfg.cmd and vim.fn.executable(cfg.cmd[1]) == 1 then
            vim.lsp.enable(name)
        end
    end
end

enable_available_servers()

-- Mason installs run asynchronously. Right after a fresh install (or after
-- mason-tool-installer finishes its first sync) the binaries weren't on $PATH
-- when we ran the loop above, so the corresponding servers got skipped.
-- Re-run the loop once Mason signals completion so they enable for the
-- already-open buffers without needing a restart.
vim.api.nvim_create_autocmd("User", {
    pattern = "MasonToolsUpdateCompleted",
    callback = function()
        vim.schedule(enable_available_servers)
    end,
})

-- ============================================================================
-- LspAttach: per-buffer keymaps & feature opt-ins.
-- The 0.12 defaults already provide grn / gra / grr / gri / grt / gO / <C-S>.
-- We add the conventional <leader>-prefixed equivalents and toggles.
-- ============================================================================

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("UserLspAttach", { clear = true }),
    callback = function(args)
        local bufnr = args.buf
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if not client then
            return
        end

        local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
        end

        map("n", "K", vim.lsp.buf.hover, "LSP hover")
        map("n", "gd", vim.lsp.buf.definition, "Go to definition")
        map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
        map("n", "gy", vim.lsp.buf.type_definition, "Go to type definition")
        map("n", "<leader>la", vim.lsp.buf.code_action, "Code action")
        map("n", "<leader>lr", vim.lsp.buf.rename, "Rename symbol")
        map("n", "<leader>lf", function()
            vim.lsp.buf.format({ async = true })
        end, "Format buffer")
        map("v", "<leader>lf", function()
            vim.lsp.buf.format({ async = true })
        end, "Format selection")
        map("n", "<leader>ls", vim.lsp.buf.signature_help, "Signature help")
        map("n", "<leader>lR", vim.lsp.buf.references, "References")
        map("n", "<leader>li", vim.lsp.buf.implementation, "Implementation")
        map("n", "<leader>lo", vim.lsp.buf.document_symbol, "Document symbols")
        map("n", "<leader>lO", vim.lsp.buf.workspace_symbol, "Workspace symbols")

        -- Inlay hints (toggle).
        if client:supports_method("textDocument/inlayHint") then
            vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
            map("n", "<leader>lh", function()
                vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
            end, "Toggle inlay hints")
        end

        -- Document highlight on CursorHold.
        if client:supports_method("textDocument/documentHighlight") then
            local hl_grp = vim.api.nvim_create_augroup("UserLspDocHL." .. bufnr, { clear = true })
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
                group = hl_grp,
                buffer = bufnr,
                callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufLeave" }, {
                group = hl_grp,
                buffer = bufnr,
                callback = vim.lsp.buf.clear_references,
            })
        end

        -- Code lens refresh.
        if client:supports_method("textDocument/codeLens") then
            vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave", "CursorHold" }, {
                buffer = bufnr,
                callback = function()
                    vim.lsp.codelens.enable(true, { bufnr = bufnr })
                end,
            })
            map("n", "<leader>lL", vim.lsp.codelens.run, "Run code lens")
        end
    end,
})

-- ============================================================================
-- Diagnostic navigation (works without an attached LSP too).
-- ============================================================================

vim.keymap.set("n", "]d", function()
    vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Next diagnostic" })

vim.keymap.set("n", "[d", function()
    vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Prev diagnostic" })

vim.keymap.set("n", "]e", function()
    vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR, float = true })
end, { desc = "Next error" })

vim.keymap.set("n", "[e", function()
    vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR, float = true })
end, { desc = "Prev error" })

vim.keymap.set("n", "<leader>ld", vim.diagnostic.open_float, { desc = "Line diagnostics" })
vim.keymap.set("n", "<leader>lq", vim.diagnostic.setloclist, { desc = "Diagnostics → loclist" })
vim.keymap.set("n", "<leader>lt", function()
    vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = "Toggle diagnostics" })
