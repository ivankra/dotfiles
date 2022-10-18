all: dep gen firefox chrome

# Install prerequisite packages
dep:
	python3 -c 'import lz4' >/dev/null 2>&1 || \
	  sudo apt-get install python3-lz4; \
	which cpp >/dev/null 2>&1 || \
	  sudo apt-get install cpp; \
	which jsonnet >/dev/null 2>&1 || \
	  sudo apt-get install jsonnet || \
	  sudo apt-get install ../packages-deb/jsonnet*.deb; \
	[ -f /usr/share/chromium/extensions/no-skip-ink/no-skip-ink.css ] || \
	  sudo apt-get install chromium-no-skip-ink || \
	  sudo apt-get install ../packages-deb/chromium-no-skip-ink_1.0_all.deb;

# Update vendored-in files and generated files.
vendor: vendor-download gen

# Re-download external dependencies into vendor
vendor-download:
	rm -rf vendor tmp
	mkdir -p tmp
	curl -s -o tmp/pyllyukko.user.js 'https://raw.githubusercontent.com/pyllyukko/user.js/master/user.js'
	curl -s -o tmp/ghacks.user.js 'https://raw.githubusercontent.com/ghacksuserjs/ghacks-user.js/master/user.js'
	mv tmp vendor

# Regenerate files in gen/
gen: gen-clean gen/user.js

gen-clean:
	rm -rf gen

gen/ghacks.json: vendor/ghacks.user.js
	mkdir -p gen
	./userjs2json.py <vendor/ghacks.user.js | grep -v _user.js.parrot >gen/ghacks.json

gen/pyllyukko.json: vendor/pyllyukko.user.js
	mkdir -p gen
	./userjs2json.py <vendor/pyllyukko.user.js >gen/pyllyukko.json

gen/user.js: firefox.jsonnet gen/ghacks.json gen/pyllyukko.json
	jsonnet -V DOWNLOAD_DIR="$$(realpath ~/Downloads)" -V HIDPI -m gen firefox.jsonnet
	jsonnet -S -m gen gen/text
	rm -f gen/text
	cat gen/user.json | sed -Ene 's/^ *("[^"]+"): (.*[^,]),?$$/user_pref(\1, \2);/p' >gen/user.js.tmp
	mv -f gen/user.js.tmp gen/user.js

# Configure firefox/chrome/chromium

firefox: gen/user.js
	./firefox.py

chrome:
	./chrome.py

.PHONY: vendor gen
