# Dan's Dotfiles

Inspired by <https://www.atlassian.com/git/tutorials/dotfiles>

## Get Started

1. Install [Xcode](https://developer.apple.com/xcode/) and open to accept licenses.

2. Install [homebrew](https://brew.sh/).

   **Note: This should install Xcode CLI Tools**

3. Install [Github CLI](https://github.com/cli/cli) and login.

   ```shell
   brew install gh
   gh auth login
   ```

   When prompted, use browser to authenticate and select ssh protocol to create ssh key and add to Github.

4. Install dotfiles with [install script](https://github.com/dyc5828/dotfiles/blob/main/install.sh)

   ```shell
   curl -fsSL https://raw.githubusercontent.com/dyc5828/dotfiles/HEAD/install.sh | bash
   ```

5. Initaize submodules

   ```shell
   git submodule update --init --recursive
   ```

6. Set env vars in `~/.zshenv`. See 1Password for details?

7. Use brew bundle to Install brew packages with [brew bundle](https://github.com/Homebrew/homebrew-bundle). See
   [tips](https://gist.github.com/ChristopherA/a579274536aab36ea9966f301ff14f3f).

   You will need to run this command multiple times to install all packages successfully.

8. Install python 2.7.18 with pyenv and set as global.

   ```shell
   pyenv install 2.7.18
   pyenv global 2.7.18
   ```

9. Install ruby and set as global.

   ```shell
   frum install 3.1.3 // 2.7.6
   frum global 3.1.3
   ```

10. Import terminal profile from `dan-pro.terminal`

## Useful Links

[Warp and Starfish setup](https://afridi1.dev/articles/customize-warp-terminal-with-starship-and-custom-theme/)
