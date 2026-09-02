local repo_excludes = { "repos", "repos/**", "**/repos/**" }

return {
  "folke/snacks.nvim",
  ---@type snacks.Config
  opts = {
    picker = {
      sources = {
        explorer = {
          enabled = false,
          hidden = true,
          exclude = repo_excludes,
        },
        files = {
          cmd = "fd",
          hidden = true,
          exclude = repo_excludes,
        },
        grep = {
          hidden = true,
          exclude = repo_excludes,
        },
        -- Vendored subtree files are tracked, so Git-backed pickers need
        -- explicit pathspec exclusions instead of relying on gitignore.
        git_files = {
          cmd_args = { "--", ".", ":(exclude)repos/**" },
        },
        git_grep = {
          pathspec = { ":(exclude)repos/**" },
        },
      },
    },
  },
}
