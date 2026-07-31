#    _               _              
#   | |__   __ _ ___| |__  _ __ ___ 
#   | '_ \ / _` / __| '_ \| '__/ __|
#  _| |_) | (_| \__ \ | | | | | (__ 
# (_)_.__/ \__,_|___/_| |_|_|  \___|
# 
# by notrealekansh
# -----------------------------------------------------
# ~/.bashrc
# -----------------------------------------------------

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# If not running interactively, don't do anything
[[ $- != *i* ]] && return
PS1=' > '

# -----------------------------------------------------
# ALIASES
# -----------------------------------------------------

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias c='clear'
alias nf='fastfetch'
alias pf='fastfetch'
alias ff='fastfetch'

# -----------------------------------------------------
# APPS
# -----------------------------------------------------

alias cursor='cursor-agent'

# -----------------------------------------------------
# GIT
# -----------------------------------------------------
alias gs="git status"
alias ga="git add"
alias gc="git commit -m"
alias gp="git push"
alias gpl="git pull"
alias gst="git stash"
alias gsp="git stash; git pull"
alias gcheck="git checkout"
alias gcredential="git config credential.helper store"

# -----------------------------------------------------
# SYSTEM
# -----------------------------------------------------
alias update-grub='sudo grub-mkconfig -o /boot/grub/grub.cfg'

# -----------------------------------------------------
# Fastfetch 
# -----------------------------------------------------
fastfetch
export PATH="$HOME/.local/bin:$PATH"
