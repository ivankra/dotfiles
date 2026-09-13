# Update all submodules and show a changelog
update:
	git submodule update --init --remote --recursive
	git diff --submodule=log .

init:
	git submodule update --init --depth=1

deinit:
	git submodule deinit -f --all
