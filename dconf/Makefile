load: build
	cat gnome-terminal.json | json2dconf | dconf load /

build: gnome-terminal.json

gnome-terminal.json: gnome-terminal/*
	gnome-terminal/gen.sh | dconf2json --sort >gnome-terminal.json
