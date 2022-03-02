std = luajit

-- Rerun tests only if their modification time changed.
cache = true

-- Glorious list of warnings: https://luacheck.readthedocs.io/en/stable/warnings.html
ignore = {
	"311" -- Value assigned to a local variable is unused.
}


-- Exclude test files
exclude_files = { "spec/" }

-- Global objects defined by the C code
read_globals = {
  "vim",
}
