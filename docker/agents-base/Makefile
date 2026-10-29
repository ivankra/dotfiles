IMAGE := $(shell basename $(CURDIR))

# Host timezone as a zone name: $TZ if set, else the /etc/localtime symlink
# target (Linux: /usr/share/zoneinfo/X, macOS: /var/db/timezone/zoneinfo/X).
TZ ?= $(shell readlink /etc/localtime 2>/dev/null | sed -n 's|.*zoneinfo/||p')
TZ := $(or $(TZ),Etc/UTC)

all: build

build:
	podman build --build-arg TZ=$(TZ) -t $(IMAGE) .

rebuild:
	podman build --build-arg TZ=$(TZ) -t $(IMAGE) --no-cache .
