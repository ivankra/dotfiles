IMAGE := $(shell basename $(CURDIR))

all: build

build:
	podman build -t $(IMAGE) .

rebuild:
	podman build -t $(IMAGE) --no-cache .
