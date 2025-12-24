#!/bin/bash

# macOS defaults configuration
# Run this script to apply custom macOS preferences

echo "Applying macOS defaults..."

# MusicDecoy - Set media app path to YouTube Music
defaults write com.lowtechguys.MusicDecoy mediaAppPath "$HOME/Applications/Chrome Apps.localized/YouTube Music.app"

# Add more defaults write commands here as needed
# Example:
# defaults write com.apple.dock autohide -bool true
# defaults write NSGlobalDomain AppleShowAllExtensions -bool true

echo "Done! Some changes may require logout/restart to take effect."
