PACKAGES = $(patsubst %.control,%,$(wildcard *.control))

all: $(PACKAGES)

clean:
	rm -rf *.deb

version = $(shell cat $(1).control | grep ^Version: | sed -e 's/.*: \(.*\)/\1/')

define tmpl
$(1): $(1)_$(call version,$(1))_all.deb

$(1)_$(call version,$(1))_all.deb: $(1).control
	equivs-build $(1).control
endef

$(foreach pkg,$(PACKAGES),$(eval $(call tmpl,$(pkg))))
