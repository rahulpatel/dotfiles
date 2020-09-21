# Dotfiles

Run `xcode-select --install` then run the following...

```bash
cd /tmp
curl -LO https://github.com/rahulpatel/dotfiles/archive/master.zip
unzip master.zip
mv ./dotfiles-master ~/.dotfiles
cd ~/.dotfiles
script/bootstrap
```

## Themes
- Palenight
  - [Code](https://marketplace.visualstudio.com/items?itemName=Equinusocio.vsc-material-theme)
  - [iTerm](https://github.com/JonathanSpeek/palenight-iterm2)
- Light/Night Owl
  - [Code](https://marketplace.visualstudio.com/items?itemName=sdras.night-owl)
  - [iTerm](https://github.com/nickcernis/iterm2-night-owl)


## Custom Functions

### c <repo>
`cd` directly into `$PROJECTS/<repo>` if `repo` is provided, else it'll `cd` into `$PROJECTS`. This function has auto-complete.

### cgo <repo>
`cd` directly into `$PROJECTS/go/src/github.com/rahulpatel`. This function has auto-complete.

### extract <file>
Extract any archive without having to remember which command you need to run.

### kill-port <port>
Kill the process running on `<port>`.

### show-port <port>
Show the process running on `<port>`.
