all: lab lab.rstudio clean

.dotfiles:
	rm -rf .dotfiles
	cp -a ~/.dotfiles ./
	cp -a -f ~/.ssh/id_rsa.pub .dotfiles/authorized_keys >/dev/null 2>&1 || true
	cp -a -f ~/.ssh/id_ed25519.pub .dotfiles/authorized_keys >/dev/null 2>&1 || true
	cat ~/.ssh/authorized_keys >>.dotfiles/authorized_keys

lab: .dotfiles run.sh
	docker build -f Dockerfile -t lab .

lab.rstudio: lab
	docker build -f Dockerfile.rstudio -t lab-rstudio .

clean:
	rm -rf .dotfiles
