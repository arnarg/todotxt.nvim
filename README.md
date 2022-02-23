# todotxt.nvim

🚧 **Work in progress** 🚧

**There is more to come but if you really want to try it out you can follow instructions below (might not be up to date though).**

Neovim plugin to view and add tasks stored in a todo.txt format.

[![asciicast](doc/asciinema.png)](https://asciinema.org/a/DVMyXY3pvUBKNdzu5Ywy9jweE)

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

## Configuration

```lua
{
	sidebar = {
		width = 40,
	},
	capture = {
		prompt = "> ",
		width = "75%",
		position = "50%",
		-- Styled after https://swiftodoapp.com/todotxt-syntax/priority/
		-- With this, if you include any of the below keywords it will
		-- automatically use the associated priority and remove that
		-- keyword from the final task.
		alternative_priority = {
			A = "now",
			B = "next",
			C = "today",
			D = "this week",
			E = "next week",
		},
	},
	-- Highlights used in both capture prompt and tasks sidebar
	highlights = {
		project = {
			fg = "magenta",
			bg = "NONE",
			style = "NONE",
		},
		context = {
			fg = "cyan",
			bg = "NONE",
			style = "NONE",
		},
		date = {
			fg = "NONE",
			bg = "NONE",
			style = "underline",
		},
		priorities = {
			A = {
				fg = "red",
				bg = "NONE",
				style = "bold",
			},
			B = {
				fg = "magenta",
				bg = "NONE",
				style = "bold",
			},
			C = {
				fg = "yellow",
				bg = "NONE",
				style = "bold",
			},
			D = {
				fg = "cyan",
				bg = "NONE",
				style = "bold",
			},
		},
	},
}
```

## Usage

After calling setup you can open a prompt with `:ToDoTxtCapture`.
