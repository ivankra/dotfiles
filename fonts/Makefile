DOCKER := $(shell command -v podman docker container 2>/dev/null | head -1 || echo docker)

iosevka: iosevka.Dockerfile iosevka.toml
	$(DOCKER) build -f iosevka.Dockerfile -t iosevka-builder .
	$(DOCKER) run --rm -v "$$PWD:/host" iosevka-builder bash -c 'cp -R /dist/* /host' \
	  || ($(DOCKER) run --cidfile iosevka.cid iosevka-builder && \
	      $(DOCKER) cp "`cat iosevka.cid`:/dist/." . && \
	      $(DOCKER) rm "`cat iosevka.cid`" && \
	      rm -f iosevka.cid)
	#$(DOCKER) image rm iosevka-builder
