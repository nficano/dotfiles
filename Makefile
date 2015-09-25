DOTFILES := $(PWD)

install: install-bash setup-directories install-inputrc

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
	mkdir -p ~/.dotfiles
