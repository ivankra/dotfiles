install: uninstall
	mkdir -p ~/.config/systemd/user
	envsubst <~/.dotfiles/services/redshiftomatic/redshiftomatic.service >~/.config/systemd/user/redshiftomatic.service
	systemctl --user enable redshiftomatic.service
	systemctl --user start redshiftomatic.service
	@echo
	@echo Success - installed and started redshiftomatic service

install-break:
	FLAGS=--break make install

uninstall:
	if [ -f ~/.config/systemd/user/redshiftomatic.service ]; then \
	  systemctl --user stop redshiftomatic.service || true; \
	  systemctl --user disable redshiftomatic.service; \
	  rm -f ~/.config/systemd/user/redshiftomatic.service; \
	fi
