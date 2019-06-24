EQUIVS_PACKAGES = $(patsubst %.control,%,$(wildcard *.control))
DOCKER_PACKAGES = $(patsubst %.Dockerfile,%,$(wildcard *.Dockerfile))

all: $(EQUIVS_PACKAGES) $(DOCKER_PACKAGES)

clean:
	rm -rf *.deb

# Build a package out of each *.Dockerfile using docker.
# Assumes that the container will place final product into /dist/
%: %.Dockerfile
	docker build -f $< -t tmp-builder-$@ .
	rm -f $@.cid
	docker run --cidfile $@.cid tmp-builder-$@
	docker cp "$$(cat $@.cid):/dist/." ./
	docker rm "$$(cat $@.cid)" && rm -f $@.cid
	docker image rm tmp-builder-$@

get_version = $(shell cat $(1).control | grep ^Version: | sed -e 's/.*: \(.*\)/\1/')

# Build a package out of each *.control file with equivs-build
define equivs_tmpl
$(1): $(1)_$(call get_version,$(1))_all.deb

$(1)_$(call get_version,$(1))_all.deb: $(1).control
	equivs-build $(1).control
endef

$(foreach pkg,$(EQUIVS_PACKAGES),$(eval $(call equivs_tmpl,$(pkg))))
