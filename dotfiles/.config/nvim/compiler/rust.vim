if exists("current_compiler")
	finish
endif

let current_compiler = "rust"

set makeprg=cargo\ check\ --message-format=short
