# .dotfiles

Randy's dotfiles repo

Stores all my dotfiles and config files for both Linux and Windows, all in one place!

## Windows

In order to use this on Windows, the following conditions must be true:

* [Git for Windows](https://gitforwindows.org/) is installed
  * While the Git package in the MSYS2 pacman is [now maintained by the Git For Windows team](https://gitforwindows.org/install-inside-msys2-proper), the native Windows install provides better integration with tools outside MSYS2 as well in a more complete way.  You should just install Git for Windows before you install MSYS2.
* Install [MSYS2](https://www.msys2.org/)
* [Developer Mode is enabled](https://www.msys2.org/docs/symlinks/#native-windows-symlinks)
* [Windows Sudo is enabled](https://learn.microsoft.com/en-us/windows/advanced-settings/sudo/?wt.mc_id=windows_inproduct_sudo) and set to `Inline` mode

## Usage

More details can be found in the [User Guide](docs/user_guide.md)

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

## Why did I do this!?

I originally set up my dotfiles a couple of years ago using GNU Stow based on ThePrimeagen's ["Developer Fundamentals" course on FrontEndMasters](https://frontendmasters.com/courses/developer-productivity-v2/).  However, I found that some environments do not always have GNU Stow installed out of the gate.  Furthermore, I wanted a solution that would work on practically any barebones Linux install AND Windows AND something I could use both at home and at work.  This meant that my options for Windows to use Linux-style tools could not include WSL and needed native tooling.  This led me down the path of committing to either limit myself to just the bundled Git Bash...or I could try to embrace the full MSYS2 environment to get access to other tooling in the future via pacman.

Given these requirements, I set out to re-implement Stow effectively in bash scripts.  This allowed me to not also require the base system have something like Python installed already and to be basically universal, including Macs (while Catalina changed the default shell to Zsh, Bash is still installed and available).  I found that within MSYS22 that bash is not always available under /bin/bash, but can run via `/usr/bin/env bash`, which technically also makes this more compatible with using at work where the bash I "want" via our module system there may not be what's stored at /bin/bash anyway.
