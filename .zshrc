# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="/home/andrew/.oh-my-zsh"
plugins=(git zsh-syntax-highlighting zsh-autosuggestions)

# OH-MY-ZSH
source $ZSH/oh-my-zsh.sh
# User configuration

# ls -> exa
if [ "$(command -v exa)" ]; then
    unalias -m 'll'
    unalias -m 'l'
    unalias -m 'la'
    unalias -m 'ls'
    alias ls='exa -G  --color auto --icons -s type'
    alias l='exa -G --color auto --icons -a -s type'
    alias ll='exa -l --color always --icons -a -s type'
fi

alias open="xdg-open"
alias copy="xclip -i -selection clipboard "
alias yay="paru"
alias config="/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME"

cdir() {
    mkdir $1 && cd $1
}

# File extraction utility
ex ()
{
  if [ -f $1 ] ; then
    case $1 in
      *.tar.bz2)   tar xjf $1   ;;
      *.tar.gz)    tar xzf $1   ;;
      *.bz2)       bunzip2 $1   ;;
      *.rar)       unrar x $1   ;;
      *.gz)        gunzip $1    ;;
      *.tar)       tar xf $1    ;;
      *.tbz2)      tar xjf $1   ;;
      *.tgz)       tar xzf $1   ;;
      *.zip)       unzip $1     ;;
      *.Z)         uncompress $1;;
      *.7z)        7z x $1      ;;
      *.deb)       ar x $1      ;;
      *.tar.xz)    tar xf $1    ;;
      *.tar.zst)   unzstd $1    ;;      
      *)           echo "'$1' cannot be extracted via ex()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# Rick-roll
alias rr='curl -s -L https://raw.githubusercontent.com/keroserene/rickrollrc/master/roll.sh | bash'
alias archive="wget -H -r -k -p"


export GOPATH=/home/andrew/go
export SSLKEYLOGFILE=~/sslkeylog.log
export PATH=$PATH:/home/andrew/bin
export PATH="$HOME/.node_modules/bin:$PATH"
export PATH="$HOME/.cabal/bin:$PATH"

cmd=$(starship init zsh)
eval $cmd

unset QT_QPA_PLATFORMTHEME 

# fnm
export PATH=/home/andrew/.fnm:$PATH
eval "`fnm env --multi`"

# fzf config
if type rg &> /dev/null; then
  export FZF_DEFAULT_COMMAND='rg --files'
  export FZF_DEFAULT_OPTS='-m '
  #--height 50% --border'
fi

export PATH="$HOME/.cabal/bin:$HOME/.ghcup/bin:$PATH"

# zoxide
eval "$(zoxide init zsh)"
