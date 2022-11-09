# Dotfiles

## Getting Started

```bash
xcode-select --install
git clone https://github.com/rahulpatel/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./init.sh
```
## Scripts

### Adding a new `init` script

1. Create a folder with the name of the tool
2. Copy and paste `templates/init.sh` into the folder you created
3. Write the required commands in the `main()` function of the script
4. Add a call to the script to the root `/init.sh` script

### Adding a new `config`

1. Create a folder with the name of the tool
2. Copy and paste `templates/config.sh` into the folder you created
3. Add the relevant configuration into the `config.sh` file

The newly created `config.sh` will be automatically loaded by `.zshrc`.

### Adding a new `completion`

1. Create a folder with the name of the tool
2. Copy and paste `templates/completion.sh` into the folder you created
3. Add the relevant completion commands into the `completion.sh` file
