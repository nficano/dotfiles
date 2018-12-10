DOTFILES := $(PWD)

install: setup

bootstrap:
	bash $(DOTFILES)/bin/bootstrap-osx

setup:
	mkdir -p ~/.virtualenvs
	mkdir -p ~/Downloads
	mkdir -p ~/github
	mkdir -p ~/Repos
	mkdir -p ~/.pip
	rm -f ~/.bash_profile
	rm -f ~/.inputrc
	ln -fs $(DOTFILES)/bash_profile ${HOME}/.bash_profile
	ln -fs $(DOTFILES)/init.d/org.nficano.dotfiles.DropboxSync.plist ${HOME}/Library/LaunchAgents/org.nficano.dotfiles.DropboxSync.plist
	ln -fs $(DOTFILES)/rc.d/agrc ${HOME}/.agrc
	ln -fs $(DOTFILES)/rc.d/dircolors ${HOME}/.dircolors
	ln -fs $(DOTFILES)/rc.d/gitconfig ${HOME}/.gitconfig
	ln -fs $(DOTFILES)/rc.d/gitignore ${HOME}/.gitignore
	ln -fs $(DOTFILES)/rc.d/hushlogin ${HOME}/.hushlogin
	ln -fs $(DOTFILES)/rc.d/inputrc ${HOME}/.inputrc
	ln -fs $(DOTFILES)/rc.d/nanorc ${HOME}/.nanorc
	ln -fs $(DOTFILES)/rc.d/pip.conf ${HOME}/.pip/pip.conf
	ln -fs $(DOTFILES)/rc.d/tmux.conf ${HOME}/.tmux.conf
	ln -s $(DOTFILES)/bin ${HOME}/.bin
