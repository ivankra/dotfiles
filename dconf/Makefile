load: build
	cat gnome-terminal.json | ../bin/json2dconf | dconf load /

build: gnome-terminal.json

gnome-terminal.json: gnome-terminal/*
	gnome-terminal/gen.sh | ../bin/dconf2json --sort >gnome-terminal.json
