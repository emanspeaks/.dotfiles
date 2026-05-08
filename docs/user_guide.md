# User Guide

## Overview

This dotfiles system manages configuration files across machines and environments using symlinks — a re-implementation of GNU Stow in pure Bash.  Packages are the unit of organization; a machine file lists which packages are active on a given machine.  Scripts at the repo root handle deploying, updating, and managing those packages.

### Key directories and environment variables

| Variable | Default path | Purpose |
| --- | --- | --- |
| `DOTFILES` | repo root | Root of the dotfiles repo |
| `DOTCFGDIR` | `~/.config/dotfiles` | Per-machine runtime config |
| `DOTMACHFILE` | `~/.config/dotfiles/machine` | Active machine's package list (symlink into `machines/`) |
| `DOTMACHDIR` | `$DOTFILES/machines` | One file per machine, committed to the repo |
| `DOTPKGDIR` | `$DOTFILES/pkgs` | One subdirectory per available package |
| `SECRETSDIR` | `$DOTFILES/secrets` | Submodule with encrypted secrets |

`exports.sh` sets all of the above and is sourced automatically by every top-level script.  You can also source it directly in your shell profile to make these variables available interactively.

---

## First-time setup

```bash
git clone https://github.com/emanspeaks/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
git submodule update --init --recursive

# Set the master vault password, then decrypt secrets
nvim secrets/passwd/master
secrets/decrypt.sh

# Initialize this machine (creates machines/<name>, links it to DOTMACHFILE,
# and runs pull for the auto-added base and base-machine packages)
./deploy.sh <machine-name>

# Add additional packages beyond the defaults
./add.sh <package-name>
```

After `deploy.sh` completes, the `~/.local/bin/dot-*` convenience wrappers installed by the `base` package are available, so you no longer need to be in `~/.dotfiles` to run the scripts.

### Windows prerequisites

- Git for Windows (installed before MSYS2 for best native integration)
- MSYS2
- Developer Mode enabled (required for native Windows symlinks under MSYS2)

The `MSYS=winsymlinks:nativestrict` export in `exports.sh` configures MSYS2 to use native Windows symlinks rather than Junction Points or copies.

---

## Top-level scripts

All top-level scripts resolve `DOTFILES` via `readlink -f` on their own path, so they can be invoked through symlinks (such as the `~/.local/bin/dot-*` wrappers installed by the `base` package) and still find the repo correctly.

### `exports.sh`

```sh
. ~/.dotfiles/exports.sh
```

Not meant to be run directly — source it.  Sets up all `DOT*` and `SECRETSDIR` environment variables used by every other script, and automatically sources `secrets/ansible-env.sh` to export `ANSIBLE_VAULT_IDENTITY_LIST`.  You can add `. ~/.dotfiles/exports.sh` to your `.bashrc` to get these variables in interactive shells.

---

### `deploy.sh`

```bash
./deploy.sh [--debug] [--debug2] [--trace] [<machine-name>]
```

Initializes this machine in the repo.  Typically, run once per new machine, but is safe to re-run.

**What it does:**

1. If `<machine-name>` is omitted, auto-detects the machine name from the existing `DOTMACHFILE` symlink.  Aborts if neither is available.
2. Creates `machines/<machine-name>` (empty file) in the repo if it does not already exist.
3. Creates `~/.config/dotfiles/` if needed, then symlinks `~/.config/dotfiles/machine` → `machines/<machine-name>` (skipped if the symlink already exists).
4. Calls `init_machine_base_pkgdir` to create the `pkgs/base-machine` symlink pointing to `pkgs/.machines/<machine-name>` (see [Machine-specific packages](#machine-specific-packages)).
5. If the machine file is empty (new machine), auto-populates it with two packages: `base` and `base-machine`.
6. Sources and runs `pull.sh` to deploy all packages immediately.

**Arguments:**

| Argument | Required | Description |
| --- | --- | --- |
| `<machine-name>` | No (auto-detected if already deployed) | Identifier for this machine; becomes the filename under `machines/` |

**Common flags:** `--debug`, `--debug2`, `--trace` (see [Debugging flags](#debugging-flags)).

After running `deploy.sh`, add additional packages with `add.sh` or by editing `machines/<machine-name>` directly and then running `pull.sh`.

---

### `add.sh`

```bash
./add.sh [--debug] [--debug2] [--trace] <package-name>
```

Adds a package to the active machine's package list and immediately deploys it.

**What it does:**

1. Checks whether `<package-name>` is already a line in `$DOTMACHFILE`.  If so, warns and exits.
2. Appends `<package-name>` to `$DOTMACHFILE`.
3. Calls `pull.sh <package-name>` to deploy that package immediately.

**Arguments:**

| Argument | Required | Description |
| --- | --- | --- |
| `<package-name>` | Yes | Name of a package directory under `pkgs/` |

**Common flags:** `--debug`, `--debug2`, `--trace` (see [Debugging flags](#debugging-flags)).

---

### `pull.sh`

```bash
./pull.sh [--debug] [--debug2] [--trace] [<package-name>]
```

Pulls the latest repo state and deploys symlinks for all packages (or a single package) listed in the active machine file.

**What it does:**

1. Runs `git pull` to fetch upstream changes.  If that fails, continues with the local copy.
2. Reads `$DOTMACHFILE`, sorts and deduplicates the package list.
3. If `<package-name>` is given, restricts work to that single package (must already be in the machine file; otherwise exits with an error).
4. For each package:
   - If the package name matches `base-machine`, calls `init_machine_base_pkgdir` first to ensure the `pkgs/base-machine` symlink is correct.
   - If the package directory does not exist under `pkgs/`, logs a warning and skips it (not a fatal error).
   - Otherwise, calls `pull_pkg` to create symlinks (see [Linking system](#linking-system)).
5. Reports success/failure counts and exits with the number of failed packages as the exit code.

**Arguments:**

| Argument | Required | Description |
| --- | --- | --- |
| `<package-name>` | No | Restrict deployment to one package already in the machine file |

**Common flags:** `--debug`, `--debug2`, `--trace` (see [Debugging flags](#debugging-flags)).

**Exit code:** number of packages that failed (0 = all succeeded).

---

### `push.sh`

> **Not yet implemented.**  Running it will immediately abort with a fatal error.

Intended to be the reverse of `pull.sh` — copying modified files from the filesystem back into the package tree — but this direction of the workflow is not implemented yet.

---

### `drop.sh`

> **Not yet implemented.**  Running it will immediately abort with a fatal error.

Intended to remove a package from the active machine file and un-deploy its symlinks.

---

## Debugging flags

Every script that sources `utils/common.sh` (all top-level scripts) accepts these flags before any positional arguments:

| Flag | Effect |
| --- | --- |
| `--debug` | Enables debug output (`DEBUG=1`).  Prints a `[DEBUG]` prefix on internal diagnostic messages. |
| `--debug2` | Verbose debug with `file:line` prefix on every debug message (`DEBUG=2`). |
| `--trace` | Enables `set -x` bash tracing with a clean source-relative `PS4` prompt, plus sets `DEBUG=1`. |

Trace level 3 (`set_trace 3`) adds an interactive single-step trap (press Enter to advance each command).  Trace level 4 adds explicit `BREAKPOINT` pauses at annotated call sites in the linking code.  These levels are not exposed as CLI flags and require source edits to activate.

---

## Package structure

Each package lives under `pkgs/<name>/` and may contain any combination of three mount-point directories:

```text
pkgs/<name>/
├── home/          # contents are linked into ~
├── root/          # contents are linked into /   (one level skipped, see below)
├── userprofile/   # contents are linked into $USERPROFILE (Windows only)
├── noln           # optional: paths to never link as a whole (see below)
└── norecurse      # optional: subdirectory paths to not descend into
```

### `home/`

Files and directories inside `home/` are symlinked into `~` preserving the relative path.  For example, `pkgs/bash/home/.bash_profile` produces a symlink `~/.bash_profile → <dotfiles>/pkgs/bash/home/.bash_profile`.

### `root/`

Same idea but targets `/`.  The root directory itself is never linked — the script descends one extra level (`skiplevel=1`) before it starts making links, so only the contents of the top-level FHS directories (e.g. `root/etc/`, `root/usr/`) are linked.

### `userprofile/` (Windows only)

Same as `home/` but targets the Windows user profile directory (`$USERPROFILE`) via `cygpath`.  Only processed when both `pkgs/<name>/userprofile/` exists and `$USERPROFILE` is a valid directory.

---

## Machine-specific packages

Every machine automatically gets two packages added on first deploy: `base` and `base-machine`.

### `base` package

The `base` package (`pkgs/base/`) contains content common to all machines, most notably it installs convenience wrapper scripts into `~/.local/bin/`:

| Wrapper | Calls |
| --- | --- |
| `dot-add` | `add.sh` |
| `dot-deploy` | `deploy.sh` |
| `dot-pull` | `pull.sh` |
| `dot-push` | `push.sh` |
| `dot-drop` | `drop.sh` |
| `secrets-decrypt` | `secrets/decrypt.sh` |
| `secrets-encrypt` | `secrets/encrypt.sh` |
| `secrets-rmcrypt` | `secrets/rmcrypt.sh` |
| `avault` | `secrets/bin/avault.sh` |
| `avault-decrypt` | `secrets/bin/avault-decrypt.sh` |
| `avault-encrypt` | `secrets/bin/avault-encrypt.sh` |

Because these wrappers resolve their path via `readlink -f`, they work correctly whether called directly or through `$PATH`.

### `base-machine` package

The `base-machine` package is a pseudo-package name (`MACHINEPKG=base-machine`) that resolves to a machine-specific directory.  The mechanism works as follows:

- Machine-specific files live in `pkgs/.machines/<machine-name>/` inside the repo.
- `init_machine_base_pkgdir` creates a symlink `pkgs/base-machine` → `pkgs/.machines/<machine-name>`.
- `pull.sh` refreshes this symlink automatically before deploying the `base-machine` package.
- From the package system's perspective, `base-machine` is an ordinary package whose content is whatever is in `pkgs/.machines/<machine-name>/`.

This is where machine-specific configuration belongs, such as a `.bashrc.d/<machine-name>.sh` startup script.  Every machine's content lives in its own committed subdirectory under `pkgs/.machines/`, all within the same repo.

---

## Linking system

### How symlinks are created

The core of `pull_pkg` is a recursive function `pull_src_dest_skiplevel_noln`.  For each item under a package's `home/`, `root/`, or `userprofile/` tree:

1. **File** — a symlink is created at the corresponding destination path pointing back into the package directory.
2. **Directory (does not exist at destination)** — the entire directory is symlinked as a unit, unless it is listed in `noln` (see below).
3. **Directory (already exists at destination as a real directory)** — the function descends and merges, linking individual contents.
4. **Directory (already exists as a symlink to another dotfiles package)** — the existing link is replaced with a real directory, the previously-linked package's files are re-linked individually inside it, and then the current package's files are linked in alongside them.  This handles the case where two packages both want to contribute files to the same directory (e.g. both have a `home/.config/` subtree).

`safe_link` skips creating a link when the correct link already exists; it aborts if the destination is an unexpected existing file or a link pointing somewhere outside the dotfiles repo.

Each `pull_pkg` call runs in its own subshell, so a failure in one package's linking cannot corrupt the shell state of subsequent packages.

### Global `noln` lists

Certain high-traffic directories are never linked as a whole regardless of package contents, to prevent accidentally replacing your entire `~/.config` with a symlink.  These are defined in `utils/noln_lists.sh`:

- **`HOME_NOLN`** — `.local/`, `.config/`, `.bashrc.d/`, `.local/templates/`
- **`USERPROFILE_NOLN`** — everything in `HOME_NOLN` plus common Windows user-profile directories (`AppData/`, `Desktop/`, `Documents/`, etc.)
- **`ROOT_NOLN`** — all standard FHS top-level and second-level directories (`bin/`, `etc/`, `usr/bin/`, `var/log/`, etc.)

A directory in `noln` is always descended into rather than linked wholesale.

### Per-package `noln` file

A package can opt additional paths into the no-link list by adding a `noln` file at the package root.  Each line is a path relative to the package root (e.g. `home/.local/templates/` or `userprofile/.local/templates/`).  The trailing slash on a directory path is significant — it means "descend into this directory" rather than "skip this exact name entirely".

Example (`pkgs/vscode/noln`):

```text
home/.local/templates/
userprofile/.local/templates/
```

This causes the `templates/` directory to be descended into rather than linked as a whole, so individual templates can coexist with templates from other packages.

### Per-package `norecurse` file

A package can prevent the linking system from recursing into a specific subdirectory by adding a `norecurse` file at the package root.  Each line is a path relative to the package root with a trailing slash.  Useful for directories that contain auto-generated files that should not be managed as symlinks.

---

## Machine files

A machine file is a plain text file under `machines/` with one package name per line.  The active machine's file is symlinked to `~/.config/dotfiles/machine`.  Packages are deduplicated and sorted before processing.  Lines for packages whose `pkgs/` directory does not exist are skipped with a warning rather than aborting.

Example (`machines/throwbeadsnswim`):

```text
bash
throwbeadsnswim
vscode
msys2
nvim
opencode
wezterm
git
claude
pycountdown
```

You can edit the machine file directly and then run `./pull.sh` (or `dot-pull`) to apply changes.  `add.sh` is a convenience wrapper that also does the edit and immediate pull for a single package.

---

## Secrets (`secrets/`)

The `secrets/` directory is a separate Git submodule.  It stores sensitive files encrypted with [avault](https://github.com/emanspeaks/avault), a cross-platform Ansible Vault-compatible tool bundled as pre-built binaries for Linux, macOS, and Windows.

The directory layout inside `secrets/` mirrors what would appear in plaintext:

```text
secrets/
├── ciphertext/     # encrypted files (committed to git)
├── plaintext/      # decrypted files (gitignored, never committed)
├── passwd/         # vault password files (gitignored, set manually on each clone)
├── vault-ids.txt   # list of vault ID → password file mappings
└── bin/            # avault binaries and wrapper scripts
```

### Initial setup

On a fresh clone you must set vault passwords manually before any decrypt can succeed:

```bash
nvim secrets/passwd/master      # set the master vault password
secrets/decrypt.sh --passwd     # decrypt any other passwords stored in ciphertext/passwd/
secrets/decrypt.sh              # decrypt everything else
```

### `secrets/decrypt.sh`

```bash
secrets/decrypt.sh [--dry] [--passwd] [<path-to-ciphertext-file-or-dir>]
```

Decrypts files from `ciphertext/` into `plaintext/`, mirroring the directory structure.

| Flag / Argument | Description |
| --- | --- |
| `--dry` | Print commands without executing them |
| `--passwd` | Only decrypt `ciphertext/passwd/` (for initial setup or password rotation) |
| `<path>` | Decrypt a single file or directory instead of all of `ciphertext/` |

The vault ID for each file is read from the Ansible Vault header in the ciphertext file itself, so the correct identity is always used regardless of which ID is currently the default.

---

### `secrets/encrypt.sh`

```bash
secrets/encrypt.sh [--dry] [<default-vault-id> [<path-to-plaintext-file-or-dir>]]
```

Encrypts files from `plaintext/` into `ciphertext/`.  Files in `plaintext/` are gitignored; files in `ciphertext/` are committed.

| Flag / Argument | Description |
| --- | --- |
| `--dry` | Print commands without executing them |
| `<default-vault-id>` | Vault ID to use for files that have not been encrypted before (default: `master`) |
| `<path>` | Encrypt a single file or directory; requires `<default-vault-id>` to be given first |

Files that already have a corresponding ciphertext file retain their original vault ID from the ciphertext header.  To change the vault ID for an existing file, delete the ciphertext file first or edit its header.

Single-file mode is useful when adding a new secret and wanting to assign it a non-default vault ID before doing a full batch encrypt run.

---

### `secrets/rmcrypt.sh`

```bash
secrets/rmcrypt.sh [--dry] [--both] <path-to-plaintext-or-ciphertext-file-or-dir>
```

Removes the plaintext or ciphertext counterpart(s) of a given file from the repo.

| Flag / Argument | Description |
| --- | --- |
| `--dry` | Print commands without executing them |
| `--both` | Delete both the plaintext and the ciphertext file |
| `<path>` | A file or directory in either `plaintext/` or `ciphertext/` |

Without `--both`:

- If `<path>` is in `plaintext/`, deletes the matching file in `ciphertext/`.
- If `<path>` is in `ciphertext/`, deletes the matching file in `plaintext/`.

This lets you cleanly remove a secret from one side without manually computing the mirror path.

---

### `secrets/ansible-env.sh`

```bash
. secrets/ansible-env.sh
```

Exports `ANSIBLE_VAULT_IDENTITY_LIST` constructed from `vault-ids.txt`.  This script is now sourced automatically by `exports.sh`, so it runs whenever any top-level script is invoked.  You only need to source it manually if you want the variable available in an interactive shell session that has not already sourced `exports.sh`.

---

## Common workflows

### Setting up a new machine

```bash
git clone https://github.com/emanspeaks/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
git submodule update --init --recursive
nvim secrets/passwd/master
secrets/decrypt.sh
./deploy.sh <machine-name>
./add.sh bash
./add.sh git
# ... add more packages as needed
```

### Updating configs after a repo pull

```bash
dot-pull        # from anywhere, via ~/.local/bin wrapper
# or from the repo root:
./pull.sh
```

### Adding a package to a machine

```bash
dot-add <package-name>
# or from the repo root:
./add.sh <package-name>
```

### Debugging a pull that isn't linking correctly

```bash
./pull.sh --debug2 <package-name>   # verbose file:line debug
./pull.sh --trace  <package-name>   # full bash set -x trace
```

### Adding machine-specific configuration

Place files under `pkgs/.machines/<machine-name>/home/` (or `userprofile/`) following the same package layout conventions, then run `dot-pull base-machine` to deploy them.

### Adding a new secret

```bash
cp /path/to/secret secrets/plaintext/category/filename
secrets-encrypt                  # encrypts with master vault ID
# or to use a different vault ID:
secrets-encrypt other-id secrets/plaintext/category/filename
secrets-encrypt                  # batch run picks up the ID from the header
```

### Rotating a secret

```bash
nvim secrets/plaintext/category/filename
secrets-encrypt
```

### Removing a secret from both sides

```bash
secrets-rmcrypt --both secrets/plaintext/category/filename
```
