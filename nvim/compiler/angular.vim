if exists("current_compiler")
	finish
endif

let current_compiler = "angular"

set makeprg=ng\ build

CompilerSet errorformat=%EError:\ %f:%l:%c\ -\ %m,%-G%.%#


