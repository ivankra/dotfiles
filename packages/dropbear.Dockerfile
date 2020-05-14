# dropbear with ed25519 support

FROM debian:buster

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
	autoconf \
	fakeroot \
        build-essential \
        ca-certificates \
        equivs \
        git

RUN echo "deb-src http://deb.debian.org/debian buster main" >>/etc/apt/sources.list
RUN apt-get update && \
    apt-get build-dep -y dropbear

RUN mkdir /work
RUN git clone --depth=1 https://github.com/mkj/dropbear.git /work/src
RUN git clone --depth=1 https://salsa.debian.org/debian/dropbear.git /work/salsa
WORKDIR /work/src

RUN rm -rf debian && cp -a ../salsa/debian ./
RUN for f in debian/dropbear.postinst debian/dropbear-initramfs.postinst debian/initramfs/dropbear-hook; do sed -i -e 's/for keytype in [^;]\+/for keytype in dss esa ecdsa ed25519/' $f; done
RUN sed -i -e 's/(dss|rsa)/(dss|rsa|ed25519)/' debian/initramfs/dropbear-hook
RUN tail debian/initramfs/dropbear-hook
RUN echo "dropbear ($(date +%Y.%m.%d)-$(git show-ref --hash=8 HEAD)) unstable; urgency=low" >debian/changelog

RUN autoconf && autoheader && ./debian/rules binary
RUN mkdir /dist && mv /work/*.deb /dist/
RUN rm -f /dist/dropbear*dbgsym* /dist/dropbear_*_amd64.deb

# == Installation ==
# apt install ./dropbear{-bin*,-initramfs*,-run*,_*_all}.deb
# rm -f /etc/dropbear{,-initramfs}/dropbear_{dss,ecdsa,rsa}_host_key
# /usr/lib/dropbear/dropbearconvert openssh dropbear /etc/ssh/ssh_host_ed25519_key /etc/dropbear-initramfs/dropbear_ed25519_host_key
# cp /root/.ssh/authorized_keys /etc/dropbear-initramds/authorized_keys
# Set ip= kernel parameter in grub config if not using DHCP.
# update-initramfs -k all -u
