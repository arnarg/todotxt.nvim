# todotxt.nvim

🚧 **Work in progress** 🚧

**There is more to come but if you really want to try it out you can follow instructions below (might not be up to date though).**

Neovim plugin to view and add tasks stored in a todo.txt format.

[![asciicast](doc/asciinema.png)](https://asciinema.org/a/FmM892Xfbg5U76HhMgeXYJ88u)

## Requirements

- Neovim 0.5.0
- [nui.nvim](https://github.com/MunifTanjim/nui.nvim)

## Installation

With [packer.nvim](https://github.com/wbthomason/packer.nvim):
```lua
use {
	'arnarg/todotxt.nvim',
	requires = {'MunifTanjim/nui.nvim'},
}
```

## Quickstart

Add the `setup()` function to your init file.

For `init.lua`:
```lua
require('todotxt-nvim').setup({
	todo_path = "/path/to/todo.txt",
})
```

For `init.vim`:
```vim
lua <<EOF
require('todotxt-nvim').setup({
	todo_path = "/path/to/todo.txt",
})
EOF
```

## Usage

After calling setup you can open a prompt with `:ToDoTxtCapture`.
