#!/bin/bash -e
################################################################################
# This script provides a relatively automated setup of a fresh OSX machine.
# @anthonyjso
################################################################################

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODE=${HOME}/Code

mkdir -p "${CODE}"
mkdir -p ~/bin

trap 'echo "Error at $LINENO";' ERR

info() {
    printf "  [ \033[00;34m..\033[0m ] %s\n" "$1"
}

user() {
    printf "\r  [ \033[0;33m?\033[0m ] %s\n" "$1"
}

success() {
    printf "\r\033[2K  [ \033[00;32mOK\033[0m ] %s\n" "$1"
}

fail() {
    printf "\r\033[2K  [\033[0;31mFAIL\033[0m] %s\n" "$1"
    echo ''
    exit 1
}

# SSH keys required to access Git repos, etc
prereqs() {

    [ "$(find ~/.ssh | wc -l)" -gt 0 ] || fail "SSH keys required."
    ssh-add -L | grep id_rsa
    [ $? ] || ssh-add -K ~/.ssh/id_rsa

}

# Install xcode command line tools.
# https://github.com/chcokr/osx-init/blob/master/install.sh
# https://github.com/timsutton/osx-vm-templates/blob/ce8df8a7468faa7c5312444ece1b977c1b2f77a4/scripts/xcode-cli-tools.sh
install_xcode_clt() {
    if [ ! "$(which gcc)" ]; then
        touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
        PROD=$(softwareupdate -l |
            grep "\*.*Command Line" |
            head -n 1 | awk -F"*" '{print $2}' |
            sed -e 's/^ *//' | tr -d '\n')
        softwareupdate -i "$PROD" -v
    fi

    success "XCode Command Line Tools Installed"
}

# Install Homebrew package manager.
install_homebrew() {
    if [ ! "$(which brew)" ]; then
        # This can be automated to just untar the tarball and symlink the bin
        ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    fi
    info "Updating Homebrew"
    [ -O /usr/local ] || sudo chown "${USER}:admin" /usr/local
    brew update
    brew upgrade
    brew cleanup
    success "Homebrew installed"
}

install_kegs() {
    info "Installing Homebrew kegs"

    # bash completion
    brew install bash-completion

    # Linux vs BSD
    brew install coreutils

    # https://duckdb.org/
    brew install duckdb

    # ascii art
    brew install figlet

    # Nerdfont for items such as Tmux themes
    brew install font-fira-code-nerd-font

    # FZF, rigrep, and fd for fuzzy finding and searching
    brew install fd
    brew install fzf
    brew install ripgrep
    brew install rga

    # Git
    brew install git
    brew install gitui

    # gnu sed
    brew install gnu-sed --with-default-names

    # gpg
    brew install gpg

    # graphviz
    brew install graphviz

    # Nicer top
    brew install htop-osx

    # java - https://adoptium.net/installation/
    brew install --cask temurin
    brew install jenv

    # Parse and filter JSON from the command line
    brew install jmespath
    brew install jq

    # Neovim and LSPs
    brew install neovim
    brew install lua-language-server
    brew install marksman
    brew install pyright # python type checker
    brew install ruff    # python linter
    brew install typescript-language-server
    brew install vscode-langservers-extracted

    # For Node/TS development
    brew install nvm
    brew install npm

    # SSL
    brew install openssl

    # Run processes in parallel
    brew install parallel

    # Diagrams
    brew install plantuml

    # Bread and butter
    brew install pyenv
    brew install pyenv-virtualenv
    brew install pyenv-virtualenvwrapper

    # A shell script static analysis tool
    brew install shellcheck
    brew install shfmt

    # Customizable prompt for any shell
    brew install starship

    # OpenTofu/Terraform
    brew install opentofu

    # Terminal multiplexer
    brew install tmux

    # Print dirs out as a tree
    brew install tree

    # Not everything is a tar file
    brew install unrar

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

    # rustup
    brew install rustup

    # generate c/c++ interfaces for target high level lang
    brew install swig

    success "Homebrew kegs installed"
}

function install_casks() {

    # From app store
    # evernote, clamxav, google-chrome, 1Password
    # Manually: little-snitch, alfred, pycharm pro

    brew tap caskroom/cask
    brew tap homebrew/cask-fonts
    brew cask install --appdir="${HOME}/Applications" \
        docker \
        colima \
        dropbox \
        firefox \
        intellij-idea-ce \
        iterm2 \
        keyboard-cleaner \
        kindle \
        licecap \
        netnewswire \
        ngrok \
        qbserve \
        pycharm \
        rectangle \
        spotify \
        temurin
    success "Casks installed"

    colima completion bash >/usr/local/etc/bash_completion.d/colima
}

function setup_git() {
    [ -f ~/.giconfig ] && mv ~/.gitconfig ~/.gitconfig.bak
    ln -s "${DIR}/git/gitconfig" ~/.gitconfig
}

function setup_java() {
    # https://github.com/jenv/jenv/blob/master/README.md
    echo "no java setup"
}

function setup_python() {
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >>~/.bashrc
    echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >>~/.bashrc
    echo 'eval "$(pyenv init -)"' >>~/.bashrc
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >>~/.bash_profile
    echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >>~/.bash_profile
    echo 'eval "$(pyenv init -)"' >>~/.bash_profile
    echo 'alias jb='\''open -na "PyCharm.app" --args "$@"'\''' >>~/.bash_profile

    success "Setup Python virtual environments"
}

function setup_rust() {
    cargo install rusty-tags
}

function fetch_themes() {

    for repo in "git@github.com:rose-pine/iterm.git"; do
        # shellcheck disable=SC2001
        repo_dir=$(echo "${repo}" | sed 's#.*/\(.*\).git$#\1#g')
        [ -d "${CODE}/${repo_dir}" ] || git -C "$CODE" clone "$repo"
    done
    success "Third party repos installed"
}

function setup_osx() {

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

    # Set the clock format
    defaults write com.apple.menuextra.clock DateFormat -string "EE MMM d  h:mm a"

    # Expand save panel by default
    defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
    defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

    # Expand print panel by default
    defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
    defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

    # Trackpad, mouse, keyboard, Bluetooth accessories, and input

    # Trackpad: enable tap to click for this user and for the login screen
    defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
    defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
    defaults write NSGlobalDomain com.apple.mouse.scaling -float 2.5

    defaults write com.apple.driver.AppleBluetoothMultitouch.mouse MouseButtonMode -string "TwoButton"
    defaults write com.apple.driver.AppleBluetoothMultitouch.mouse MouseTwoFingerHorizSwipeGesture -int 2

    # Trackpad: map bottom right corner to right-click
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
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

    # Turn off autocorrect
    defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled 0

    # Screen

    # Require password immediately after sleep or screen saver begins
    defaults write com.apple.screensaver askForPassword -int 1
    defaults write com.apple.screensaver askForPasswordDelay -int 0

    # Save screenshots to the desktop
    mkdir -p "${HOME}/Pictures/screenshots"
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

    # Reduce motion
    defaults write com.apple.Accessibility ReduceMotionEnabled -bool true

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

function install_dotfiles() {
    [ -h "${HOME}/.bash_profile" ] || ln -s "${DIR}/bash/bashrc" "${HOME}/.bash_profile"
    success "Installed dotfiles"
}

function install_work() {
    # idea being to have work specific script sourced and executed here
    info 'install work'
}

function setup_tmux() {
    # Terminal multiplexer
    brew install tmux

    [ -h ~/.tmux.conf ] || ln -s "${DIR}"/tmux/tmux.conf "${HOME}"/.tmux.conf

    # Plugin Manager
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    echo "set -g @plugin 'tmux-plugins/tpm'" >>"${HOME}"/.tmux.conf
    echo "set -g @plugin 'tmux-plugins/tmux-sensible'" >>"${HOME}"/.tmux.conf
    echo "set -g @plugin 'tmux-plugins/tmux-resurrect'" >>"${HOME}"/.tmux.conf
    echo "set -g @resurrect-strategy-nvim 'session'" >>"${HOME}"/.tmux.conf
    echo "run '~/.tmux/plugins/tpm/tpm'" >>"${HOME}"/.tmux.conf # must be at bottom
}

# install plugins with lazy.nvim
function setup_nvim() {
    [ -d ~/.config/nvim/ ] || mkdir -p "$HOME"/.config/nvim
    [ -h ~/.config/nvim/init.lua ] || ln -s "${DIR}"/nvim/init.vim "$HOME"/.config/nvim/init.lua
    npm install -g neovim
    cargo install harper-ls --locked
}

install_fonts() {
    font_dir=~/Library/Fonts
    curl -o /tmp/FiraCode_1.206.zip https://github.com/tonsky/FiraCode/releases/download/1.206/FiraCode_1.206.zip
    unzip /tmp/FiraCode_1.206.zip -d "$font_dir"
}

install_hours() {
    [ -d ~/bin ] || mkdir ~/bin
    [ -L ~/bin/hours ] || ln -s "${DIR}/hours" ~/bin/hours
}

if [ "$0" != "$_" ]; then
    echo "Uncomment these"
    # prereqs
    # install_xcode_clt
    # install_homebrew
    # install_casks
    # install_kegs
    # setup_git
    # setup_python
    # fetch_themes
    # install_dotfiles
    # install_work
    # setup_osx
    # install_fonts
    # setup_nvim # depends on nvm/npm, rustup/cargo
    # setup_tmux
    # install_hours
fi
