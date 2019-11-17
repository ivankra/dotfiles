all: dep gen firefox chromium

# Install prerequisite packages
dep:
	python3 -c 'import lz4' >/dev/null 2>&1 || \
	  sudo apt-get install python3-lz3; \
	[ -x /usr/bin/cpp ] || \
	  sudo apt-get install cpp; \
	[ -x /usr/bin/equivs-build ] || \
	  sudo apt-get install equivs; \
	[ -x /usr/bin/jsonnet ] || \
	  sudo apt-get install jsonnet || \
	  sudo apt-get install ../packages-deb/jsonnet_0.14.0_amd64.deb; \
	[ -f /usr/share/chromium/extensions/no-skip-ink/no-skip-ink.css ] || \
	  sudo apt-get install chromium-no-skip-ink || \
	  sudo apt-get install ../packages-deb/chromium-no-skip-ink_1.0_all.deb;

# Re-download external dependencies into vendor/
vendor:
	rm -f vendor tmp
	mkdir -p tmp
	curl -s -o tmp/pyllyukko.user.js 'https://raw.githubusercontent.com/pyllyukko/user.js/master/user.js'
	curl -s -o tmp/ghacks.user.js 'https://raw.githubusercontent.com/ghacksuserjs/ghacks-user.js/master/user.js'
	mv tmp vendor

# Regenerate files in gen/
gen: gen-clean gen/user.js

gen-clean:
	rm -rf gen

gen/ghacks.json: vendor vendor/ghacks.user.js
	mkdir -p gen
	./userjs2json.py <vendor/ghacks.user.js | grep -v _user.js.parrot >gen/ghacks.json

gen/pyllyukko.json: vendor vendor/pyllyukko.user.js
	mkdir -p gen
	./userjs2json.py <vendor/pyllyukko.user.js >gen/pyllyukko.json

gen/user.js: firefox.jsonnet gen/ghacks.json gen/pyllyukko.json
	jsonnet -V DOWNLOAD_DIR="$$(realpath ~/Downloads)" -V HIDPI -m gen firefox.jsonnet
	cat gen/user.json | sed -Ene 's/^ *("[^"]+"): (.*[^,]),?$$/user_pref(\1, \2);/p' >gen/user.js.tmp
	mv -f gen/user.js.tmp gen/user.js

gen/firefox-policies-json_1.0_all.deb: gen/user.js ../packages/firefox-policies-json.control
	equivs-build ../packages/firefox-policies-json.control
	mv firefox-policies-json_1.0_all.deb gen/firefox-policies-json_1.0_all.deb

# Configure firefox/chromium

firefox: gen/user.js gen/firefox-policies-json_1.0_all.deb
	./firefox.py

chromium:
	./chromium.py
