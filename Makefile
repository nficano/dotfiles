DOTFILES := $(PWD)

install:
	$(MAKE) setup-tree
	@echo "NOTE: mac-provision was removed and is pending a rewrite;"
	@echo "      macOS provisioning (Brewfile/defaults/dock) is not run by 'make install' yet."

deploy-patch:
	bumpversion patch
	git push
	git push --tags

deploy-minor:
	bumpversion minor
	git push
	git push --tags

deploy-major:
	bumpversion major
	git push
	git push --tags

create-brewfile:
	brew bundle dump --force --file=$(DOTFILES)/setup/macos/Brewfile

setup-tree:
	mkdir -p ${HOME}/.virtualenvs
	mkdir -p ${HOME}/Downloads
	mkdir -p ${HOME}/code
	mkdir -p ${HOME}/Repos
	mkdir -p ${HOME}/.pip
	mkdir -p ${HOME}/.environment
	rm -f ${HOME}/.bash_profile
	rm -f ${HOME}/.inputrc
	rm -f ${HOME}/.bin
	ln -fsn $(DOTFILES)/shell/bash/profile ${HOME}/.bash_profile
	ln -fsn $(DOTFILES)/home/agrc ${HOME}/.agrc
	ln -fsn $(DOTFILES)/home/dircolors ${HOME}/.dircolors
	ln -fsn $(DOTFILES)/home/direnvrc ${HOME}/.direnvrc
	ln -fsn $(DOTFILES)/home/gitconfig ${HOME}/.gitconfig
	ln -fsn $(DOTFILES)/home/gitignore ${HOME}/.gitignore
	ln -fsn $(DOTFILES)/home/gitmessage ${HOME}/.gitmessage
	ln -fsn $(DOTFILES)/home/hushlogin ${HOME}/.hushlogin
	ln -fsn $(DOTFILES)/home/inputrc ${HOME}/.inputrc
	ln -fsn $(DOTFILES)/home/nanorc ${HOME}/.nanorc
	ln -fsn $(DOTFILES)/home/pip.conf ${HOME}/.pip/pip.conf
	ln -fsn $(DOTFILES)/home/tmux.conf ${HOME}/.tmux.conf
	ln -fsn $(DOTFILES)/home/lesskey ${HOME}/.lesskey
	ln -s $(DOTFILES)/bin ${HOME}/.bin
	@# Shared, append-only bash history living in Dropbox (symlinked).
	@# No-op on machines without Dropbox (history stays a local file there).
	@if [ -d "${HOME}/Dropbox" ]; then \
		mkdir -p "${HOME}/Dropbox/system"; \
		if [ -f "${HOME}/.bash_history" ] && [ ! -L "${HOME}/.bash_history" ] && [ ! -e "${HOME}/Dropbox/system/bash_history" ]; then \
			cp "${HOME}/.bash_history" "${HOME}/Dropbox/system/bash_history"; \
		fi; \
		touch "${HOME}/Dropbox/system/bash_history"; \
		ln -fsn "${HOME}/Dropbox/system/bash_history" "${HOME}/.bash_history"; \
		echo "history: linked ~/.bash_history -> ~/Dropbox/system/bash_history"; \
	else \
		echo "history: no ~/Dropbox found; leaving ~/.bash_history as a local file"; \
	fi
