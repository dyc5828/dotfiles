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

   Initialize submodules

   ```shell
   dot submodule update --init --recursive
   ```

1. Update environment variables and secrets

   ```shell
   ~/.zshenv
   ~/.gitconfig
   ```

1. Install [Homebrew](https://brew.sh/) and [bundle](https://docs.brew.sh/Brew-Bundle-and-Brewfile)

   ```shell
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

   Run bundle install. _May need to run multiple times due to errors/flakiness_

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

1. Install python. See python [versions](https://devguide.python.org/versions/)

   ```shell
   pyenv install 2.7.18 # python 2 required for legacy tools
   pyenv global 2.7.18
   ```

1. Install ruby. See ruby [versions](https://www.ruby-lang.org/en/downloads/branches/)

   ```shell
   frum install 3.1.3 // 2.7.6
   frum global 3.1.3
   ```

1. Software Checklist

   Utilities

   - [ ] [SoundSource](https://rogueamoeba.com/soundsource/)
   - [ ] [1Password](https://1password.com/downloads/mac/)
   - [ ] [TablePlus](https://tableplus.com/mac)
   - [ ] [Postman](https://www.postman.com/downloads/)

   Browsers

   - [ ] [Arc](https://arc.net/)
   - [ ] [Dia](https://www.diabrowser.com/)
   - [ ] [Google Chrome](https://www.google.com/chrome/)

   Code

   - [ ] [Docker Desktop](https://www.docker.com/products/docker-desktop/)
      - Install completions https://docs.docker.com/engine/cli/completion/#zsh
   - [ ] [Android Studio](https://developer.android.com/studio)
   - [ ] [Xcode](https://apps.apple.com/us/app/xcode/id497799835?mt=12)
   - [ ] [Cursor](https://cursor.com/download)

   Work

   - [ ] [Slack](https://slack.com/downloads/mac)
   - [ ] [Notion](https://www.notion.so/desktop)

## Usage

`dot` command functions as git but always points to ~

Get latest dotfiles

```shell
dot pull
```

Make updates to tracked dotfiles

```shell
dot status
dot diff file/with/updates
dot add file/with/updates
dot commit -m 'my updates'
dot push origin main
```

Add and track new dotfiles files. Be sure to purge secrets!

```shell
dot add new/file/to/track
dot commit -m 'new files'
dot push origin main
```

## Useful Resources

[Warp and Starfish setup](https://devops-crux.com/posts/09-2023-terminal-setup/)

[React Native MacOS Android Setup](https://reactnative.dev/docs/set-up-your-environment?platform=android)

[Xcode CLT Install Guide](https://mac.install.guide/commandlinetools/)

[Brew Bundle Tips](https://gist.github.com/ChristopherA/a579274536aab36ea9966f301ff14f3f)

## Deprecated Steps

- Install [Github CLI](https://github.com/cli/cli) and login.

  ```shell
  brew install gh
  gh auth login
  ```

  When prompted, use browser to authenticate and select ssh protocol to create ssh key and add to Github.

- Import terminal profile from `dan-pro.terminal`
