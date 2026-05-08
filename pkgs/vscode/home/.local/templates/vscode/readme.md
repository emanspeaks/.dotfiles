# .dotfiles

Randy's dotfiles repo

## Usage

```bash
git clone https://github.com/emanspeaks/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
git submodule update --init --recursive
nvim secrets/passwd/master
secrets/decrypt.sh

# now deploy the new machine, this creates a new machine file in the repo
./deploy.sh <machine name>

# add packages to the machine, if not already configured in the machine file
./add.sh <package name>

# pull the latest configs for the packages
./pull.sh
```

* `exports.sh`: common exports you probably want in your `.bashrc` or similar

