if exists("current_compiler")
	finish
endif

let current_compiler = "java_test"

set makeprg=~/.local/bin/scripts/filter_stacktrace.sh



" CompilerSet errorformat=%.%#at\ %f(%m:%l),%-A%.%#
CompilerSet errorformat=%E%f:%l:\ %m,%C%m,%-Z%p^,%-C%.%#


