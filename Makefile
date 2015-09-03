DOTFILES := $(PWD)

install: install-bash install-virtualenvwrapper \
		 install-inputrc

install-bash:
	rm -f ~/.bash_profile
	ln -fs $(DOTFILES)/bash_profile ${HOME}/.bash_profile

install-virtualenvwrapper:
	mkdir -p ~/.virtualenvs

install-inputrc:
	rm -f ~/.inputrc
	ln -fs $(DOTFILES)/inputrc ${HOME}/.inputrc

