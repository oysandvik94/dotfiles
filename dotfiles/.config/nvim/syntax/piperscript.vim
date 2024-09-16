" Vim syntax file
" Language: Piperscript
" Maintainer: Your Name
" Latest Revision: 2024-09-10

if exists("b:current_syntax")
  finish
endif

" Keywords
syn keyword piperConditional if else
syn keyword piperKeyword let fn return print push last

" Operators
syn match piperOperator "\v[-+*/=<>!~]"
syn match piperOperator "\v\:"

" Types and Constants
syn keyword piperBoolean true false
syn keyword piperConstant null

" Delimiters
syn match piperDelimiter "[,{}()\[\]]"

" Functions
syn match piperFunction "\<\w\+\ze("

" Comments (assuming # for comments, adjust if different)
syn match piperComment "#.*$"

" Strings
syn region piperString start=/"/ skip=/\\"/ end=/"/ oneline

" Numbers
syn match piperNumber "\<\d\+\>"
syn match piperFloat "\<\d\+\.\d*\>"

" Variables
syn match piperVariable "\<\w\+\>"

" Block start/end
syn match piperBlockStart ":\s*$"
syn match piperBlockEnd "\~"

" Highlighting links
hi def link piperConditional Conditional
hi def link piperKeyword Keyword
hi def link piperOperator Operator
hi def link piperBoolean Boolean
hi def link piperConstant Constant
hi def link piperDelimiter Delimiter
hi def link piperFunction Function
hi def link piperComment Comment
hi def link piperString String
hi def link piperNumber Number
hi def link piperFloat Float
hi def link piperVariable Identifier
hi def link piperBlockStart Special
hi def link piperBlockEnd Special

let b:current_syntax = "piperscript"
