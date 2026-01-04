IMAGE := $(shell basename $(CURDIR))

all: deps build

deps:
	make -C ../editors-base

build:
	podman build -t $(IMAGE) .
