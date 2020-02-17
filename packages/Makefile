# Usage:
# $ make <package>
#
# Debugging docker builds: make <package>-sh to build and jump to shell
# at the end of build script, before copying files out from it.

EQUIVS_PACKAGES = $(patsubst %.control,%,$(wildcard *.control))
DOCKER_PACKAGES = $(patsubst %.Dockerfile,%,$(wildcard *.Dockerfile))
SHELL_PACKAGES = $(patsubst %.sh,%,$(wildcard *.sh))

all: $(EQUIVS_PACKAGES) $(DOCKER_PACKAGES) $(SHELL_PACKAGES)

clean:
	rm -rf *.deb

# Build a package out of each *.Dockerfile using docker.
# Assumes that the container will place final product into /dist/
%: %.Dockerfile
	docker build -f $< -t builder-$@ .
	rm -f $@.cid
	docker run --cidfile $@.cid builder-$@
	docker cp "$$(cat $@.cid):/dist/." ./
	docker rm "$$(cat $@.cid)" && rm -f $@.cid
	docker image rm builder-$@

%-sh: %.Dockerfile
	docker build -f $< -t builder-$@ .
	rm -f $@.cid
	docker run --cidfile $@.cid builder-$@
	docker run -it builder-$@ /bin/bash
	docker cp "$$(cat $@.cid):/dist/." ./
	docker rm "$$(cat $@.cid)" && rm -f $@.cid

%: %.sh
	./$<

get_version = $(shell cat $(1).control | grep ^Version: | sed -e 's/.*: \(.*\)/\1/')

# Build a package out of each *.control file with equivs-build
define equivs_tmpl
$(1): $(1)_$(call get_version,$(1))_all.deb
	echo "Built $(1)_$(call get_version,$(1))_all.deb"

$(1)_$(call get_version,$(1))_all.deb: $(1).control
	equivs-build $(1).control
endef

$(foreach pkg,$(EQUIVS_PACKAGES),$(eval $(call equivs_tmpl,$(pkg))))
