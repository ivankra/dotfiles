IMAGE := $(shell basename $(CURDIR))

all: deps build

deps:
	make -C ../../docker/editors/editors-base

build:
	podman build -t $(IMAGE) .
