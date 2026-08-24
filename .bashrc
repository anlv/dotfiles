#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias ll='ls -lah --color=auto'
alias l='ls -lh --color=auto'
alias grep='grep --color=auto'
alias rm="trash --verbose"
alias dot='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
PS1='[\u@\h \W]\$ '
