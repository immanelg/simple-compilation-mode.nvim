.SILENT:
.PHONY: all
all:
	@echo "The main way to use this plugin is to start compilation with CompileMode.compile_again()"
	@echo "then recompile with the same keybinding."
	@echo ""
	@echo "This Makefile prints an example compilation output,"
	@echo "similar to what gcc, grep, find or whatever would print."
	@echo ""
	@echo "Press <cr> on any of the lines below to jump to locations."
	@echo ""
	grep -n -H --color=always 'interactive terminal' readme.md
	grep -n -H --color=always 'compile_again' readme.md
	grep -n -H --color=always 'compile_again' readme.md
	grep -n -H --color=always -r 'nvim_set_hl' plugin/
	@echo ""
	@echo "Or some other keys:"
	@echo " <space>k to show floating preview"
	@echo " r to recompile"
	@echo " q to close the terminal"
	@echo " <c-c> to interrupt"
	@echo ""


