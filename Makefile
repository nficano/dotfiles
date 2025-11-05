DOTFILES := $(PWD)
PENTOOL_DIR := $(DOTFILES)/tools/pentool
PENTOOL_VENV := $(PENTOOL_DIR)/.venv
PENTOOL_PYTHON := $(PENTOOL_VENV)/bin/python
PENTOOL_DIST := $(PENTOOL_DIR)/dist
PENTOOL_DEPS := $(PENTOOL_DIST)/deps
PENTOOL_PEX := $(PENTOOL_DIST)/pentool.pex

install:
	$(MAKE) setup-tree
	"$(DOTFILES)/setup/macos/mac-provision"

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

.PHONY: pentool-pex
pentool-pex: $(PENTOOL_PEX)
	@echo "PEX artifact created at $(PENTOOL_PEX)"

$(PENTOOL_PEX): $(PENTOOL_PYTHON)
	rm -rf $(PENTOOL_DIST)
	mkdir -p $(PENTOOL_DIST)
	$(PENTOOL_PYTHON) -m build --wheel --no-isolation --outdir $(PENTOOL_DIST) $(PENTOOL_DIR)
	mkdir -p $(PENTOOL_DEPS)
	$(PENTOOL_PYTHON) -m pip download --dest $(PENTOOL_DEPS) --only-binary=:all: "pydantic>=2.7,<3.0"
	$(PENTOOL_PYTHON) -m pex pentool --find-links $(PENTOOL_DIST) --find-links $(PENTOOL_DEPS) --no-index -c pentool -o $(PENTOOL_PEX)

$(PENTOOL_PYTHON):
	python3 -m venv $(PENTOOL_VENV)
	$(PENTOOL_PYTHON) -m pip install --upgrade pip
	$(PENTOOL_PYTHON) -m pip install build pex "setuptools>=67" wheel
