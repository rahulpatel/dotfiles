return {
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',
  config = function()
    require('nvim-treesitter.configs').setup {
      ensure_installed = {
        'bash',
        'go',
        'html',
        'javascript',
        'jsdoc',
        'lua',
        'markdown',
        'typescript',
        'vim',
        'vimdoc',
      },

      auto_install = true,

      indent = {
        enable = true,

        disable = {
          'ruby',
        },
      },

      highlight = {
        enable = true,

        -- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
        --  If you are experiencing weird indenting issues, add the language to
        --  the list of additional_vim_regex_highlighting and disabled languages for indent.
        additional_vim_regex_highlighting = {
          'markdown',
          'ruby',
        },
      },
    }

    local treesitter_parser_config = require('nvim-treesitter.parsers').get_parser_configs()
    treesitter_parser_config.templ = {
      install_info = {
        url = 'https://github.com/vrischmann/tree-sitter-templ.git',
        files = { 'src/parser.c', 'src/scanner.c' },
        branch = 'master',
      },
    }

    vim.treesitter.language.register('templ', 'templ')
  end,
}
