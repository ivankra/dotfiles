IMAGE := $(shell basename $(CURDIR))

all: deps build

deps:
	make -C ../agents-base

build:
	podman build -t $(IMAGE) --no-cache .
