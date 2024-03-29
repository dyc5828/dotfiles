git clone --bare https://github.com/dyc5828/dotfiles.git $HOME/.dotfiles
function dot {
   /usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME $@
}
mkdir -p .dotfiles-backup
dot checkout
if [ $? = 0 ]; then
  echo "Checked out dotfiles.";
  else
    echo "Backing up pre-existing dot files.";
    config checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | xargs -I{} mv {} .dotfiles-backup/{}
fi;
dot checkout
dot config status.showUntrackedFiles no
