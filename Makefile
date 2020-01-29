DOTFILES := $(PWD)

install: setup

bootstrap:
	bash $(DOTFILES)/misc/bootstrap

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

setup:
	mkdir -p ~/.virtualenvs
	mkdir -p ~/Downloads
	mkdir -p ~/github
	mkdir -p ~/Repos
	mkdir -p ~/.pip
	rm -f ${HOME}/.bash_profile
	rm -f ${HOME}/.inputrc
	rm -f ${HOME}/.bin
	ln -fsn $(DOTFILES)/bash_profile ${HOME}/.bash_profile
	ln -fsn $(DOTFILES)/rc.d/agrc ${HOME}/.agrc
	ln -fsn $(DOTFILES)/rc.d/dircolors ${HOME}/.dircolors
	ln -fsn $(DOTFILES)/rc.d/gitignore ${HOME}/.gitignore
	ln -fsn $(DOTFILES)/rc.d/gitmessage ${HOME}/.gitmessage
	ln -fsn $(DOTFILES)/rc.d/hushlogin ${HOME}/.hushlogin
	ln -fsn $(DOTFILES)/rc.d/inputrc ${HOME}/.inputrc
	ln -fsn $(DOTFILES)/rc.d/nanorc ${HOME}/.nanorc
	ln -fsn $(DOTFILES)/rc.d/pip.conf ${HOME}/.pip/pip.conf
	ln -fsn $(DOTFILES)/rc.d/tmux.conf ${HOME}/.tmux.conf
	ln -s $(DOTFILES)/bin ${HOME}/.bin
