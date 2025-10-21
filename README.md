# Selective Updater for Arch Linux

`selective_updater.sh` is a command-line utility for Arch Linux and its derivatives that enhances the `yay` package manager by providing an interactive, package-by-package update process. It allows you to review each available update and decide whether to install it, skip it, or save your preference for future updates.

This tool is ideal for users who want more control over their system updates, preventing unwanted or potentially problematic packages from being upgraded automatically.



## Key Features

-   **Interactive Updates**: Prompts you for each package, giving you full control over the upgrade process.
-   **Save Your Preferences**:
    -   **Always Upgrade**: Mark trusted packages to be upgraded automatically in the future.
    -   **Never Upgrade**: Blacklist packages you want to manage manually or keep at a specific version.
-   **AUR Support**: Use the `-a` flag to check for updates exclusively from the Arch User Repository (AUR).
-   **Session-Only Choices**: Your `yes`/`no` choices are for the current session only, unless you explicitly save them as a preference.
-   **Configuration Override**: Use the `-i` flag to ignore all saved settings for a fresh update session.
-   **Robust Upgrades**: Each selected package is upgraded individually. A failure in one package won't stop the rest of the update process.

## Prerequisites

This script is designed for Arch-based Linux distributions and requires the `yay` AUR helper to be installed.

-   [yay - An AUR Helper written in Go](https://github.com/Jguer/yay)

## Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/rpirsc13/yay-selective-updater.git
    cd selective-updater
    ```

2.  **Make the script executable:**
    ```bash
    chmod +x selective_updater.sh
    ```

3.  **(Optional) Create a symbolic link** for easy access from anywhere in your terminal:
    ```bash
    sudo ln -s "$(pwd)/selective_updater.sh" /usr/local/bin/update
    ```
    Now you can run the script by simply typing `update` in your terminal.

## Usage

Run the script from your terminal:

```bash
./selective_updater.sh
```

### Command-Line Options

  - `-a`: **AUR Only**: Restricts the update check to packages from the Arch User Repository (AUR).
  - `-i`: **Ignore Settings**: Ignores all saved "Always Yes" and "Always No" preferences for the current session. This is useful when you need to re-evaluate a package you previously blacklisted.

### How it Works

1.  The script first refreshes your package databases using `yay -Sy`.
2.  It then fetches a list of all packages with available updates.
3.  If you have saved preferences, it automatically queues the "Always Upgrade" packages and skips the "Never Upgrade" ones.
4.  For all other packages, it will prompt you with the following choices:
      - `y` (Yes): Queue this package for an upgrade in this session only.
      - `n` (No): Skip this package in this session only.
      - `a` (Always): Queue the package for an upgrade and add it to your "Always Upgrade" list for future updates.
      - `w` (Whitelist/Ignore/Never): Skip the package and add it to your "Never Upgrade" list for future updates.
5.  After you've reviewed all packages, the script will list the final set of packages to be upgraded and proceed to install them one by one.

## Configuration

The script stores your preferences in a simple configuration file located at:

`~/.config/selective-updater/.settings`

This file contains two key-value pairs:

  - `ALWAYS_YES`: A comma-separated list of packages you always want to upgrade.
  - `ALWAYS_NO`: A comma-separated list of packages you never want to upgrade.

You can edit this file manually to add or remove packages.
