DOTFILES := $(PWD)

install:
	setup-tree
	bash $(DOTFILES)/setup/macos/mac-provision

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
	mkdir -p ${HOME}/.config/copyx
	rm -f ${HOME}/.bash_profile
	rm -f ${HOME}/.inputrc
	rm -f ${HOME}/.bin
	ln -fsn $(DOTFILES)/home/.config/copyx/config.yml ${HOME}/.config/copyx/config.yml
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
