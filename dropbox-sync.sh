#!/bin/bash

# -auto     accept all non-conflicting actions
# -batch    ask no questions
# -prefer   if conflict, which directory takes precedence
# -silent   stfu

unison $HOME/Library/Fonts/ $HOME/Dropbox/Fonts/ -auto -batch -prefer $HOME/Library/Fonts/
