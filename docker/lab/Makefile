IMAGE=lab

lab:
	rm -rf .dotfiles /tmp/dotfileslab
	cp -a ~/.dotfiles /tmp/dotfileslab
	mv /tmp/dotfileslab .dotfiles
	cp -a -f ~/.ssh/id_rsa.pub .dotfiles/authorized_keys >/dev/null 2>&1 || true
	cp -a -f ~/.ssh/id_ed25519.pub .dotfiles/authorized_keys >/dev/null 2>&1 || true
	cat ~/.ssh/authorized_keys >>.dotfiles/authorized_keys
	docker build -f Dockerfile -t $(IMAGE) .
	rm -rf .dotfiles
