DOTFILES := $(PWD)

install:
	install-bash
	setup-directories
	install-inputrc
	setup-git

bootstrap:
	bash $(DOTFILES)/bootstrap_osx.sh

install-bash:
	rm -f ~/.bash_profile
	ln -fs $(DOTFILES)/bash_profile ${HOME}/.bash_profile

install-inputrc:
	rm -f ~/.inputrc
	ln -fs $(DOTFILES)/inputrc ${HOME}/.inputrc

setup-directories:
	mkdir -p ~/.virtualenvs
	mkdir -p ~/Projects
	mkdir -p ~/Downloads
	mkdir -p ~/Repos

setup-git:
	ln -fs $(DOTFILES)/gitconfig ${HOME}/.gitconfig
	ln -fs $(DOTFILES)/gitignore ${HOME}/.gitignore
