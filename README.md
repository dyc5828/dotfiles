# Dan's Dotfiles

Inspired by <https://www.atlassian.com/git/tutorials/dotfiles>

## Get Started

1. Install [Xcode Command Line Tools](https://mac.install.guide/commandlinetools/4) and to accept licenses

   ```shell
   xcode-select –-install
   ```

   Verify installation

   ```shell
   xcode-select -p # /Library/Developer/CommandLineTools
   # or
   git --version
   ```

1. Install dotfiles with [script](https://github.com/dyc5828/dotfiles/blob/main/install.sh)

   ```shell
   curl -fsSL https://raw.githubusercontent.com/dyc5828/dotfiles/HEAD/install.sh | bash
   ```

1. Update environment variables and secrets

   ```shell
   ~/.zshenv
   ~/.gitconfig
   ```

1. Install [Homebrew](https://brew.sh/) and [bundle](https://docs.brew.sh/Brew-Bundle-and-Brewfile)

   ``` shell
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

   Run bundle install. *May need to run multiple times due to errors/flakiness*

   ```shell
   brew bundle install
   ```

   After bundle is installed, run [Zulu JDK Installer](https://reactnative.dev/docs/set-up-your-environment?platform=android)

   ```shell
   # Get path to where cask was installed to find the JDK installer
   brew info --cask zulu@17

   # ==> zulu@17: <version number>
   # https://www.azul.com/downloads/
   # Installed
   # /opt/homebrew/Caskroom/zulu@17/<version number> (185.8MB) (note that the path is /usr/local/Caskroom on non-Apple Silicon Macs)
   # Installed using the formulae.brew.sh API on 2024-06-06 at 10:00:00

   # Navigate to the folder
   open /opt/homebrew/Caskroom/zulu@17/<version number> # or /usr/local/Caskroom/zulu@17/<version number>
   ```  

1. *Optional:* Install python

   ```shell
   pyenv install 2.7.18
   pyenv global 2.7.18
   ```

1. *Optional:* Install ruby

   ```shell
   frum install 3.1.3 // 2.7.6
   frum global 3.1.3
   ```

## Useful Resources

[Warp and Starfish setup](https://devops-crux.com/posts/09-2023-terminal-setup/)

[React Native MacOS Android Setup](https://reactnative.dev/docs/set-up-your-environment?platform=android)

[Xcode CLT Install Guide](https://mac.install.guide/commandlinetools/)

[Brew Bundle Tips](https://gist.github.com/ChristopherA/a579274536aab36ea9966f301ff14f3f)

## Deprecated Steps

* Install [Github CLI](https://github.com/cli/cli) and login.

   ```shell
   brew install gh
   gh auth login
   ```

   When prompted, use browser to authenticate and select ssh protocol to create ssh key and add to Github.

* Import terminal profile from `dan-pro.terminal`

* Initialize submodules

   ```shell
   git submodule update --init --recursive
   ```