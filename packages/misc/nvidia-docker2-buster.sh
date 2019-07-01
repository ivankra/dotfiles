#!/bin/bash
set -eux -o pipefail

src=$(mktemp -du)
git clone https://github.com/NVIDIA/nvidia-docker.git "$src"

(cd "$src" && git checkout cd0f1e335c689a118057c83fed39a594d1b9e1a0)

cat >>"$src/Makefile" <<'EOF'

18.09.7-debian10: ARCH := amd64
18.09.7-debian10:
	$(DOCKER) build --build-arg VERSION_ID="9" \
                        --build-arg RUNTIME_VERSION="$(RUNTIME_VERSION)+docker18.09.7-3" \
                        --build-arg DOCKER_VERSION="docker-ce (= 5:18.09.7~3-0~debian-buster)" \
                        --build-arg PKG_VERS="$(VERSION)+docker18.09.7" \
                        --build-arg PKG_REV="$(PKG_REV)" \
                        -t "nvidia/nvidia-docker2/debian:10-docker18.09.7" -f Dockerfile.debian .
	$(MKDIR) -p $(DIST_DIR)/debian10/$(ARCH)
	$(DOCKER) run  --cidfile $@.cid "nvidia/nvidia-docker2/debian:10-docker18.09.7"
	$(DOCKER) cp $$(cat $@.cid):/dist/. $(DIST_DIR)/debian10/$(ARCH)
	$(DOCKER) rm $$(cat $@.cid) && rm $@.cid
EOF

(cd "$src" && make 18.09.7-debian10)
cp "$src"/dist/debian10/amd64/nvidia-docker2*.deb ./
rm -rf "$src"
