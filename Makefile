DOTFILES := $(PWD)

install: setup-shell setup-directories install-inputrc setup-git

bootstrap:
	bash $(DOTFILES)/bootstrap_osx.sh

setup-shell:
	rm -f ~/.bash_profile
	ln -fs $(DOTFILES)/bash_profile ${HOME}/.bash_profile
	ln -fs $(DOTFILES)/hushlogin ${HOME}/.hushlogin

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
