DOTFILES := $(PWD)

install: setup-shell setup-directories install-inputrc setup-git setup-tmux setup-pip setup-agrc

bootstrap:
	bash $(DOTFILES)/bootstrap_osx.sh

setup-tmux:
	ln -fs $(DOTFILES)/tmux.conf ${HOME}/.tmux.conf

setup-shell:
	rm -f ~/.bash_profile
	ln -fs $(DOTFILES)/bash_profile ${HOME}/.bash_profile
	ln -fs $(DOTFILES)/hushlogin ${HOME}/.hushlogin

setup-pip:
	mkdir ~/.pip
	ln -fs $(DOTFILES)/pip.conf ${HOME}/.pip/pip.conf


install-inputrc:
	rm -f ~/.inputrc
	ln -fs $(DOTFILES)/inputrc ${HOME}/.inputrc

setup-agrc:
	ln -fs $(DOTFILES)/agrc ${HOME}/.agrc

setup-directories:
	mkdir -p ~/.virtualenvs
	mkdir -p ~/github
	mkdir -p ~/Downloads
	mkdir -p ~/Repos

setup-git:
	ln -fs $(DOTFILES)/gitconfig ${HOME}/.gitconfig
	ln -fs $(DOTFILES)/gitignore ${HOME}/.gitignore
