# https://github.com/getsops/sops
FROM debian:testing

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        dpkg-dev \
        git \
        gnupg

# Go version used by upstream for this release (go version -m on the release binary).
# Hashes from https://go.dev/dl/?mode=json&include=all
ARG GO_VERSION=1.26.5
ARG GO_SHA256_amd64=5c2c3b16caefa1d968a94c1daca04a7ca301a496d9b086e17ad77bb81393f053
ARG GO_SHA256_arm64=fe4789e92b1f33358680864bbe8704289e7bb5fc207d80623c308935bd696d49
RUN ARCH="$(dpkg --print-architecture)" && \
    case "$ARCH" in \
      amd64) SUM="${GO_SHA256_amd64}" ;; \
      arm64) SUM="${GO_SHA256_arm64}" ;; \
      *) echo "unsupported arch $ARCH" >&2; exit 1 ;; \
    esac && \
    curl -fsSL -o /tmp/go.tgz "https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz" && \
    echo "${SUM}  /tmp/go.tgz" | sha256sum -c - && \
    tar -C /usr/local -xzf /tmp/go.tgz && \
    rm /tmp/go.tgz
ENV PATH=/usr/local/go/bin:$PATH

# Latest release: https://github.com/getsops/sops/releases/tag/v3.13.3
ARG SOPS_VERSION=3.13.3
ARG SOPS_COMMIT=26e2f4784ca61353082c32dbd987c25eda086dc9
ARG SOPS_SIGNER=1CBD23A64DD703A808AF66E71E60B8598833B166

RUN git clone --depth=1 -b "v${SOPS_VERSION}" https://github.com/getsops/sops.git /src
WORKDIR /src

# Verify pinned commit and the tag's signature
RUN test "$(git rev-parse HEAD)" = "${SOPS_COMMIT}" && \
    curl -fsSL https://github.com/felixfontein.gpg | gpg --batch --import && \
    git verify-tag --raw "v${SOPS_VERSION}" 2>&1 | tee /dev/stderr | \
        grep -q "^\[GNUPG:\] VALIDSIG .* ${SOPS_SIGNER}$" && \
    grep -q "Version = \"${SOPS_VERSION}\"" version/version.go

# Same flags as upstream's .goreleaser.yaml; go.sum pins module hashes
ENV GOPATH=/go CGO_ENABLED=0 GOTOOLCHAIN=local GOFLAGS=-mod=readonly
RUN go mod download && go mod verify && \
    go build -trimpath \
        -ldflags "-s -w -X github.com/getsops/sops/v3/version.Version=${SOPS_VERSION}" \
        -o /pkg/usr/local/bin/sops ./cmd/sops && \
    /pkg/usr/local/bin/sops --version --disable-version-check

# Reproducibility: must match upstream's release binary bit-for-bit
RUN ARCH="$(dpkg --print-architecture)" && \
    SUM="$(curl -fsSL "https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.checksums.txt" | \
        awk -v f="sops-v${SOPS_VERSION}.linux.${ARCH}" '$2 == f { print $1 }')" && \
    test -n "${SUM}" && \
    echo "${SUM}  /pkg/usr/local/bin/sops" | sha256sum -c -

RUN ARCH="$(dpkg --print-architecture)" && \
    mkdir -p /pkg/DEBIAN /pkg/usr/share/doc/sops && \
    cp LICENSE README.rst /pkg/usr/share/doc/sops/ && \
    { \
      echo "Package: sops"; \
      echo "Version: ${SOPS_VERSION}"; \
      echo "Section: dotfiles"; \
      echo "Priority: optional"; \
      echo "Maintainer: none"; \
      echo "Architecture: ${ARCH}"; \
      echo "Homepage: https://github.com/getsops/sops"; \
      echo "Description: Simple and flexible tool for managing secrets"; \
    } >/pkg/DEBIAN/control && \
    mkdir /dist && \
    dpkg-deb --root-owner-group --build /pkg "/dist/sops_${SOPS_VERSION}_${ARCH}.deb"
