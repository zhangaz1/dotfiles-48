#!/bin/sh
# shellcheck disable=SC1117

# Functions {{{1

###########################################################
# Install configuration files only if the program they
# configure is installed.
#
# Arguments:
#   $1               Program
#   $2, $3, $4, etc. Configuration files
###########################################################
conditional_install() {
  if command -v "$1" > /dev/null 2>&1; then
    shift
    while [ $# -ne 0 ]; do
      if [ -e "$HOME/$1" ]; then
        printf "Replacing %s\n" "$1"
      else
        printf "Installing %s\n" "$1"
      fi
      cp "$1" "$HOME"
      shift
    done
  fi
}

###########################################################
# Clone a repo or update it with a pull.
#
# Arguments
#   $1 Username/Repository
#   $2 Branch (if other than master)
###########################################################
github_clone_or_update() {
  REPO=$(echo "$1" | awk -F/ '{ printf "%s", $2 }')
  if [ ! -d "$REPO" ]; then
    (git clone https://github.com/"$1".git; cd "$REPO" || return; [ -n "$2" ] \
      && git checkout "$2")
  else
    (cd "$REPO" || return; git pull; [ "$2" != '' ] && git checkout "$2")
  fi
}

# }}}1

[ ! -d themes ] && mkdir themes

cd themes || exit

github_clone_or_update "agkozak/polyglot" develop

[ ! -d "$HOME/.zplugin/plugins/agkozak---agkozak-zsh-prompt" ] \
  && github_clone_or_update "agkozak/agkozak-zsh-prompt" develop

cd ..

conditional_install vi .exrc

if command -v dircolors > /dev/null 2>&1; then
	echo '.dircolors'
	github_clone_or_update "agkozak/dircolors-zenburn"
  cp dircolors-zenburn/dircolors "$HOME/.dircolors"
fi

conditional_install bash .bash_profile .bashrc .inputrc

echo '.editorconfig'
cp .editorconfig "$HOME"

conditional_install lesspipe .lessfilter
conditional_install lesspipe.sh .lessfilter

conditional_install lynx .lynx.cfg

echo .profile
echo .shrc
cp .profile .shrc ..

if [ -e "$HOME/.vimrc" ] \
  && ! cmp ./.vimrc "$HOME/.vimrc" > /dev/null 2>&1; then
  conditional_install vim .vimrc .exrc
  vim +PlugInstall +qall
else
  conditional_install vim .vimrc .exrc
fi

if command -v nvim > /dev/null 2>&1; then
  echo 'Linking ~/.vimrc to ~/config/nvim/init.vim'
  if ! command -v vim > /dev/null 2>&1; then
    cp .vimrc "$HOME"
  fi
  if [ ! -d "$HOME/.config/nvim" ]; then
    ln -s "$HOME/.vim" "$HOME/.config/nvim"
  fi
  if [ ! -f "$HOME/.config/nvim/init.vim" ]; then
    ln -s "$HOME/.vimrc" "$HOME/.config/nvim/init.vim"
  fi
fi

conditional_install zsh .zshenv .zprofile .zshrc

conditional_install csh .cshrc

conditional_install screen .screenrc

systeminfo=$( uname -a )

case $systeminfo in
	*BSD*|*bsd*|DragonFly*)
		echo .login_conf
		cp .login_conf "$HOME"
	;;
	*raspberrypi*)
		echo .config/lxterminal
		cp .config/lxterminal/lxterminal.conf "$HOME/.config/lxterminal"
	;;
	*Msys|*Cygwin)
		echo .minttyrc
		github_clone_or_update "agkozak/zenburn.minttyrc" develop
	;;
esac

case $systeminfo in
  *Cygwin)
    echo .Xresources
    cp .Xresources.cygwin ../.Xresources
    ;;
esac

if command -v tmux > /dev/null 2>&1; then
	echo .tmux.conf
  cp .tmux.conf ..
	if [ ! -d "$HOME/.tmux" ]; then
		echo Installing tpm
		git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
	fi
fi

if command -v emacs > /dev/null 2>&1; then
  if [ ! -d "$HOME/.emacs.d" ]; then
    mkdir "$HOME/.emacs.d"
  fi
  echo Installing ~/.emacs./init.el
  cp ./.emacs.d/init.el "$HOME/.emacs.d"
fi

if command -v phpstorm > /dev/null 2>&1 \
  || [ -d '/c/Program Files/JetBrains' ] \
  || [ -d '/cygdrive/c/Program Files/JetBrains' ] \
  || [ -d '/mnt/c/Program Files/JetBrains' ]; then
  echo Installing .ideavimrc
  cp .ideavimrc "$HOME"
fi

conditional_install mysql .editrc

# vim: ft=sh:fdm=marker:ts=2:sts=2:sw=2:et
