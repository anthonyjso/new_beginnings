#!/bin/bash -e
################################################################################
# This script provides a relatively automated setup of a fresh OSX machine.
# @anthonyjso
################################################################################

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CODE=${HOME}/code

mkdir -p ${CODE}

trap 'echo "Error at $LINENO";' ERR

info () {
  printf "  [ \033[00;34m..\033[0m ] $1\n"
}

user () {
  printf "\r  [ \033[0;33m?\033[0m ] $1\n"
}

success () {
  printf "\r\033[2K  [ \033[00;32mOK\033[0m ] $1\n"
}

fail () {
  printf "\r\033[2K  [\033[0;31mFAIL\033[0m] $1\n"
  echo ''
  exit 1
}

# SSH keys required to access Git repos, etc
prereqs () {

    [ $(find ~/.ssh | wc -l) -gt 0 ] || fail "SSH keys required."
    key_installed=$(ssh-add -L | grep id_rsa)
    [ $? ] || ssh-add -K ~/.ssh/id_rsa

}

# Install xcode command line tools.
# https://github.com/chcokr/osx-init/blob/master/install.sh
# https://github.com/timsutton/osx-vm-templates/blob/ce8df8a7468faa7c5312444ece1b977c1b2f77a4/scripts/xcode-cli-tools.sh
install_xcode_clt () {
    if [ ! $(which gcc) ]; then
        touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress;
        PROD=$(softwareupdate -l |
        grep "\*.*Command Line" |
            head -n 1 | awk -F"*" '{print $2}' |
            sed -e 's/^ *//' | tr -d '\n')
        softwareupdate -i "$PROD" -v;
    fi

    success "XCode Command Line Tools Installed"
}


# Install Homebrew package manager.
install_homebrew () {
    if [ ! $(which brew) ]; then
        # This can be automated to just untar the tarball and symlink the bin
        ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    fi
    info "Updating Homebrew"
    [ -O /usr/local ] || sudo chown ${USER}:admin /usr/local
    brew update
    brew upgrade
    brew cleanup
    success "Homebrew installed"
}

install_kegs () {
    info "Installing Homebrew kegs"

    # http://www.debian-administration.org/article/316/An_introduction_to_bash_completion_part_1
    brew install bash-completion

    # Install large binaries http://caskroom.io/
    brew install caskroom/cask/brew-cask

    # Emacs dep management
    brew install cask

    # Linux vs BSD
    brew install coreutils

    # Tried and gave up and will try again
    brew install emacs --with-cocoa

    # ascii art
    brew install figlet

    # no looking back at SVN
    brew install git

    # Eventually I'll sit down and write something with it
    brew install go

    # Nicer top
    brew install htop-osx

    # Parse and filter JSON from the command line
    brew install jq

    # SSL
    brew install openssl

    # Create machine images
    brew install packer

    # Run processes in parallel
    brew install parallel

    # Bread and butter
    brew install python

    # Lightweight and useful DB for hacks
    brew install sqlite

    # Nicer than mdfind and fast
    brew install the_silver_searcher

    # Terminal multiplexer
    brew install tmux

    # Print dirs out as a tree
    brew install tree

    # Not everything is a tar file
    brew install unrar

    # For those C explorations
    brew install --HEAD valgrind


    # Required by coreutils
    brew install xz

    # vs curl -O
    brew install wget

    # ctags
    brew install ctags-exuberant

    # dependencies
    brew install gdbm gmp libevent libyaml oniguruma

    # node...
    brew install npm

    # vim
    brew install macvim --with-lua --with-override-system-vim

    # jenv
    brew install jenv

    # ruby and rbenv
    brew install rbenv ruby-build

    success "Homebrew kegs installed"
}

function install_casks () {

    # From app store
    # evernote, clamxav, google-chrome, 1Password
    # Manually: little-snitch, alfred, pycharm pro


    brew cask install --appdir="/Applications" \
        caffeine \
        chromecast \
        cyberduck \
        firefox \
        flux \
        gas-mask \
        github-desktop \
        hostbuddy \
        intellij-idea-ce \
        iterm2 \
        java \
        keyboard-cleaner \
        kindle \
        mysqlworkbench \
        screenhero \
        skitch \
        spectacle \
        sublime-text \
        vagrant \
        virtualbox

    success "Casks installed"

}

function setup_python () {
    mkdir -p ${CODE}/venv
    pip install virtualenv virtualenvwrapper

    success "Setup Python virtual environments"
}

function fetch_themes () {

    for repo in git@github.com:neil477/base16-emacs.git \
        https://github.com/adilosa/base16-idea.git \
        https://github.com/chriskempson/base16-iterm2.git \
        https://github.com/chriskempson/base16-shell.git \
        https://github.com/chriskempson/vim-tomorrow-theme.git \
        https://github.com/chriskempson/base16-vim.git; do

        repo_dir=$(echo ${repo} | sed 's#.*/\(.*\).git$#\1#g')
        [ -d ${CODE}/${repo_dir} ] || git -C $CODE clone $repo;
    done
    success "Third party repos installed"
}

function setup_osx () {

    info "Configuring OSX"

    # UI/UX

    # Reveal IP address, hostname, OS version, etc. when clicking the clock
    # in the login window
    sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName

    # Check for software updates daily, not just once per week
    defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1

    # Disable smart quotes as they’re annoying when typing code
    defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

    # Disable smart dashes as they’re annoying when typing code
    defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

    # Menu bar: hide the Time Machine and User icons
    for domain in ~/Library/Preferences/ByHost/com.apple.systemuiserver.*; do
        defaults write "${domain}" dontAutoLoad -array \
            "/System/Library/CoreServices/Menu Extras/TimeMachine.menu" \
            "/System/Library/CoreServices/Menu Extras/User.menu"
    done

    defaults write com.apple.systemuiserver menuExtras -array \
        "/System/Library/CoreServices/Menu Extras/Bluetooth.menu" \
        "/System/Library/CoreServices/Menu Extras/AirPort.menu" \
        "/System/Library/CoreServices/Menu Extras/Battery.menu" \
        "/System/Library/CoreServices/Menu Extras/Clock.menu"

    # Expand save panel by default
    defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
    defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

    # Expand print panel by default
    defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
    defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

    # Trackpad, mouse, keyboard, Bluetooth accessories, and input

    # Trackpad: enable tap to click for this user and for the login screen
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
    defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
    defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
    defaults write NSGlobalDomain com.apple.mouse.scaling -float 2.5

    # Trackpad: map bottom right corner to right-click
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
    defaults -currentHost write NSGlobalDomain com.apple.trackpad.trackpadCornerClickBehavior -int 1
    defaults -currentHost write NSGlobalDomain com.apple.trackpad.enableSecondaryClick -bool true

    # Enable full keyboard access for all controls
    # (e.g. enable Tab in modal dialogs)
    defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

    # Disable press-and-hold for keys in favor of key repeat
    defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

    # Set a blazingly fast keyboard repeat rate
    defaults write NSGlobalDomain InitialKeyRepeat -int 10 # normal minimum is 15 (225 ms)
    defaults write NSGlobalDomain KeyRepeat -int 1

    # Use F keys as standard keys...requires reboot :/
    defaults write -g com.apple.keyboard.fnState -boolean true

    # Screen

    # Require password immediately after sleep or screen saver begins
    defaults write com.apple.screensaver askForPassword -int 1
    defaults write com.apple.screensaver askForPasswordDelay -int 0

    # Save screenshots to the desktop
    mkdir -p "${HOME}/Desktop/screenshots"
    defaults write com.apple.screencapture location -string "${HOME}/Desktop/screenshots"

    # Save screenshots in PNG format (other options: BMP, GIF, JPG, PDF, TIFF)
    defaults write com.apple.screencapture type -string "png"

    # Dock, Dashboard, and hot corners

    # Enable highlight hover effect for the grid view of a stack (Dock)
    defaults write com.apple.dock mouse-over-hilite-stack -bool true

    # Set the icon size of Dock items to 36 pixels
    defaults write com.apple.dock tilesize -int 36

    # Change minimize/maximize window effect
    defaults write com.apple.dock mineffect -string "scale"

    # Minimize windows into their application’s icon
    defaults write com.apple.dock minimize-to-application -bool true

    # Enable spring loading for all Dock items
    defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool true

    # Show indicator lights for open applications in the Dock
    defaults write com.apple.dock show-process-indicators -bool true

    # Wipe all (default) app icons from the Dock
    # This is only really useful when setting up a new Mac, or if you don’t use
    # the Dock to launch apps.
    defaults write com.apple.dock persistent-apps -array

    # Don’t animate opening applications from the Dock
    defaults write com.apple.dock launchanim -bool false

    # Speed up Mission Control animations
    defaults write com.apple.dock expose-animation-duration -float 0.1

    # Disable Dashboard
    defaults write com.apple.dashboard mcx-disabled -bool true

    # Don’t show Dashboard as a Space
    defaults write com.apple.dock dashboard-in-overlay -bool true

    # Don’t automatically rearrange Spaces based on most recent use
    defaults write com.apple.dock mru-spaces -bool false

    # Remove the auto-hiding Dock delay
    defaults write com.apple.dock autohide-delay -float 0
    # Remove the animation when hiding/showing the Dock
    defaults write com.apple.dock autohide-time-modifier -float 0

    # Automatically hide and show the Dock
    defaults write com.apple.dock autohide -bool true

    # Make Dock icons of hidden applications translucent
    defaults write com.apple.dock showhidden -bool true

    # Disable the Launchpad gesture (pinch with thumb and three fingers)
    #defaults write com.apple.dock showLaunchpadGestureEnabled -int 0

    # Reset Launchpad, but keep the desktop wallpaper intact
    # find "${HOME}/Library/Application Support/Dock" -name "*-*.db" -maxdepth 1 -delete

    # Add a spacer to the left side of the Dock (where the applications are)
    #defaults write com.apple.dock persistent-apps -array-add '{tile-data={}; tile-type="spacer-tile";}'
    # Add a spacer to the right side of the Dock (where the Trash is)
    #defaults write com.apple.dock persistent-others -array-add '{tile-data={}; tile-type="spacer-tile";}'

    # Hot corners
    # Possible values:
    #  0: no-op
    #  2: Mission Control
    #  3: Show application windows
    #  4: Desktop
    #  5: Start screen saver
    #  6: Disable screen saver
    #  7: Dashboard
    # 10: Put display to sleep
    # 11: Launchpad
    # 12: Notification Center
    # Top left screen corner → Mission Control
    defaults write com.apple.dock wvous-tl-corner -int 4
    defaults write com.apple.dock wvous-tl-modifier -int 0
    # Top right screen corner → Desktop
    defaults write com.apple.dock wvous-tr-corner -int 3
    defaults write com.apple.dock wvous-tr-modifier -int 0
    # Bottom left screen corner → Start screen saver
    defaults write com.apple.dock wvous-bl-corner -int 5
    defaults write com.apple.dock wvous-bl-modifier -int 0

    # Termina/iterm2

    # Install the Solarized Dark theme for iTerm
    # TODO: install themes...
    # open "${HOME}/init/Solarized Dark.itermcolors"

    # Don’t display the annoying prompt when quitting iTerm
    defaults write com.googlecode.iterm2 PromptOnQuit -bool false

    # potentially kill processes to allow settings to take effect
    # like dock and finder...

    success "Finished configuring OSX"
}

function install_dotfiles () {
    [ -h ${HOME}/.bashrc ] || ln -s ${DIR}/bash/bashrc ${HOME}/.bashrc
    [ -h ${HOME}/.vimrc ] || ln -s ${DIR}/vim/vimrc ${HOME}/.vimrc
    success "Installed dotfiles"
}

function install_work () {
    # idea being to have work specific script sourced and executed here
    info 'install work'
}

function setup_vim () {
    #pathogen
    mkdir -p ~/.vim/autoload ~/.vim/bundle && \
    curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim


    for repo in git@github.com:othree/yajs.vim.git \
                git@github.com:rking/ag.vim.git \
                git@github.com:tacahiroy/ctrlp-funky.git \
                git@github.com:kien/ctrlp.vim.git \
                git@github.com:Raimondi/delimitMate.git \
                git@github.com:mattn/emmet-vim.git \
                git@github.com:scrooloose/nerdtree.git \
                git@github.com:kien/rainbow_parentheses.vim.git \
                git@github.com:vim-scripts/slimv.vim.git \
                git@github.com:scrooloose/syntastic.git \
                git@github.com:vim-scripts/taglist.vim.git \
                git@github.com:craigemery/vim-autotag.git \
                git@github.com:skammer/vim-css-color.git \
                git@github.com:tpope/vim-fugitive.git \
                git@github.com:vitaly/vim-gitignore.git \
                git@github.com:pangloss/vim-javascript.git \
                git@github.com:jelera/vim-javascript-syntax.git \
                git@github.com:tpope/vim-jdaddy.git \
                git@github.com:heavenshell/vim-jsdoc.git \
                git@github.com:mxw/vim-jsx.git \
                git@github.com:plasticboy/vim-markdown.git \
                git@github.com:edsono/vim-matchit.git \
                git@github.com:tpope/vim-sensible.git \
                git@github.com:duganchen/vim-soy.git \
                git@github.com:tpope/vim-surround.git \
                git@github.com:avakhov/vim-yaml.git; do

        # only clone the plugin if it doesn't exist yet
        plugin_dir=$(echo ${repo} |cut -d '/' -f2)
        plugin_dir=${plugin_dir%.git}
        [ -d ~/.vim/bundle/${plugin_dir} ] || git -C ~/.vim/bundle clone ${repo}
    done

    # Symlink themes
    mkdir -p ${HOME}/.vim/colors
    for theme_repo in ${CODE}/vim-tomorrow-theme \
                 ${CODE}/base16-vim; do
        for theme in ${theme_repo}/colors/*; do
            link_name=~/.vim/colors/$(basename ${theme})
            [ -L ${link_name} ] || ln -s ${theme} ${link_name}
        done
    done
}

if [ $0 != $_ ]; then
    prereqs
    install_xcode_clt
    install_homebrew
    install_kegs
    install_casks
    setup_python
    fetch_themes
    install_dotfiles
    install_work
    setup_osx
    setup_vim
fi
