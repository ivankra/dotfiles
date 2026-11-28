.PHONY: init update pull deinit

# Clone missing submodules, leave already checked out ones alone
init:
	for d in */; do [ -e "$$d.git" ] || echo "$${d%/}"; done | xargs -r git submodule update --init --recursive --depth=1 --

# Check out pinned revisions, cloning missing submodules
update:
	git submodule update --init --recursive --depth=1

# Update all submodules to latest upstream and show a changelog
pull:
	git submodule update --init --remote --recursive
	git diff --submodule=log .

deinit:
	git submodule deinit -f --all
