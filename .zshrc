export DF_HOME=~/dotfiles
export DF_CORE=$DF_HOME/core
export DF_USER=$DF_HOME/personal

# Create common color functions.
autoload -U colors
colors

# Include the default Spin zshrc
# This file has a number of useful functions for detecting the status of the Spin environment.
# We can still overwrite the terminal display later on, if we want.
if [ $SPIN ]; then
  if [ -e /etc/zsh/zshrc.default.inc.zsh ]; then
    source /etc/zsh/zshrc.default.inc.zsh

    dev config set default.account Shopify
  fi
fi

source $DF_CORE/environment.zsh
source $DF_USER/environment.zsh
source $DF_CORE/filter_history.zsh

alias vin='f() { vi $(find node_modules/$1 -name $2*) };f'

alias gs='git status'
alias gsh='git show HEAD'
alias grab='git rebase --abort'
alias grim='MAIN_BRANCH=$(git remote show origin | grep HEAD | cut -d " " -f 5) && git rebase -i "origin/$MAIN_BRANCH"';
alias grc='git rebase --continue'
alias gdc='git diff --cached'
alias gss='f() { git stash show stash@{$1} }; f'
alias gbranches='git branch --sort=committerdate'