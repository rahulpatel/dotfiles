# Dotfiles

My dotfiles to automate the setup of a new MacOS installation.

## Getting Started

```bash
xcode-select --install
git clone https://github.com/rahulpatel/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./init.sh
```

## How does this work?

`./init.sh` manually calls each tools `init.sh` file
  - This is to setup tools in a certain order
  - All `*.symlink` files are automatically symlinked to `~/.<filename>`
    - The `.symlink` extension is removed when symlinking

Once complete, all applications and shell environment will be setup.

When opening a new terminal, the `.zshrc` file will:
- Source `$HOME/.localrc` if it exists
- Source all `config.sh` files from this repo
- Source all `completion.sh` files from this repo
- Source all `alias.sh` files from this repo
- Setup and apply oh-my-zsh

## Scripts

### Adding a new `init` script

1. Create a folder with the name of the tool
2. Copy and paste `templates/init.sh` into the folder you created
3. Write the required commands in the `main()` function of the script
4. Add a call to the script to the root `/init.sh` script

### Adding a new `config` script

1. Create a folder with the name of the tool
2. Copy and paste `templates/config.sh` into the folder you created
3. Add the relevant configuration into the `config.sh` file

The newly created `config.sh` will be automatically loaded by `.zshrc`.

### Adding a new `completion` script

1. Create a folder with the name of the tool
2. Copy and paste `templates/completion.sh` into the folder you created
3. Add the relevant completion commands into the `completion.sh` file

The newly created `completion.sh` will be automatically loaded by `.zshrc`.

### Adding a new `alias` script

1. Create a folder with the name of the tool
2. Copy and paste `templates/alias.zsh` into the folder you created
3. Add the relevant aliases into the `alias.zsh` file

The newly created `alias.zsh` will be automatically loaded by `.zshrc`.
