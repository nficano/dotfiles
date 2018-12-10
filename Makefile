DOTFILES := $(PWD)

install: setup

bootstrap:
	bash $(DOTFILES)/bin/bootstrap-osx

setup:
	mkdir -p ~/.virtualenvs
	mkdir -p ~/Downloads
	mkdir -p ~/github
	mkdir -p ~/Repos
	mkdir ~/.pip
	rm -f ~/.bash_profile
	rm -f ~/.inputrc
	ln -fs $(DOTFILES)/agrc ${HOME}/.agrc
	ln -fs $(DOTFILES)/bash_profile ${HOME}/.bash_profile
	ln -fs $(DOTFILES)/dircolors ${HOME}/.dircolors
	ln -fs $(DOTFILES)/gitconfig ${HOME}/.gitconfig
	ln -fs $(DOTFILES)/gitignore ${HOME}/.gitignore
	ln -fs $(DOTFILES)/hushlogin ${HOME}/.hushlogin
	ln -fs $(DOTFILES)/inputrc ${HOME}/.inputrc
	ln -fs $(DOTFILES)/nanorc ${HOME}/.nanorc
	ln -fs $(DOTFILES)/pip.conf ${HOME}/.pip/pip.conf
	ln -fs $(DOTFILES)/tmux.conf ${HOME}/.tmux.conf
	ln -s $(DOTFILES)/bin ${HOME}/.bin
