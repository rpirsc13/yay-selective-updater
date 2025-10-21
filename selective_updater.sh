#!/bin/bash

# This script selectively upgrades packages using yay.
# It lists all packages that have available updates and asks for confirmation
# before proceeding to upgrade each one. It also allows saving preferences
# for packages to always or never upgrade.

# --- Configuration ---
AUTO_YES=false
AUR_ONLY=false
IGNORE_SETTINGS=false
CONFIG_DIR="$HOME/.config/selective-updater"
CONFIG_FILE="$CONFIG_DIR/.settings"

# --- Functions ---

# Function to ensure the configuration directory and file exist.
setup_config() {
    mkdir -p "$CONFIG_DIR"
    touch "$CONFIG_FILE"
}

# Function to read a setting value from the config file.
read_setting() {
    local key=$1
    grep "^$key=" "$CONFIG_FILE" | cut -d'=' -f2
}

# Function to update or add a setting in the config file.
update_setting() {
    local key=$1
    local package=$2
    local current_value=$(read_setting "$key")

    # Check if the package is already in the list to avoid duplicates.
    if [[ ",$current_value," == *",$package,"* ]]; then
        return
    fi

    if [ -z "$current_value" ]; then
        # If the key doesn't exist or is empty, create it.
        echo "$key=$package" >> "$CONFIG_FILE"
    else
        # If the key exists, append the new package.
        local new_value="$current_value,$package"
        # Use sed to find and replace the entire line.
        sed -i "s|^$key=.*|$key=$new_value|" "$CONFIG_FILE"
    fi
}

# --- Argument Parsing ---
while getopts "ai" opt; do
  case ${opt} in
    a)
      AUR_ONLY=true
      ;;
    i)
      IGNORE_SETTINGS=true
      ;;
    \?)
      echo "Usage: $(basename "$0") [-a] [-i]"
      exit 1
      ;;
  esac
done

# --- Script Body ---

setup_config

# Load "always yes" and "always no" package lists from settings.
always_yes_str=$(read_setting "ALWAYS_YES")
always_no_str=$(read_setting "ALWAYS_NO")

# Convert comma-separated strings into arrays.
IFS=',' read -r -a ALWAYS_YES_PKGS <<< "$always_yes_str"
IFS=',' read -r -a ALWAYS_NO_PKGS <<< "$always_no_str"

echo "Refreshing package databases..."
yay -Sy

# Fetch the list of all upgradable packages.
if [ "$AUR_ONLY" = true ]; then
    echo "Filtering for AUR packages only."
    upgradable_packages=$(yay -Qua | awk '{print $1}')
else
    upgradable_packages=$(yay -Qu | awk '{print $1}')
fi

if [ -z "$upgradable_packages" ]; then
    echo "All packages are up to date. Nothing to do."
    exit 0
fi

packages_to_upgrade=()
packages_to_ask=()


if [ "$IGNORE_SETTINGS" = true ]; then
    echo "Ignoring saved settings and asking for all packages."
    # If ignoring settings, all packages go into the "ask" list.
    read -r -a packages_to_ask <<< "$upgradable_packages"
else
    # Pre-process the list of upgradable packages based on saved settings.
    for package in $upgradable_packages; do
        # Check if the package is in the ALWAYS_YES list.
        if [[ " ${ALWAYS_YES_PKGS[*]} " =~ " ${package} " ]]; then
            packages_to_upgrade+=("$package")
            echo "Auto-selecting '$package' for upgrade (based on saved setting)."
        # Check if the package is in the ALWAYS_NO list.
        elif [[ " ${ALWAYS_NO_PKGS[*]} " =~ " ${package} " ]]; then
            echo "Skipping '$package' (based on saved setting)."
        # If not in either list, we need to ask the user.
        else
            packages_to_ask+=("$package")
        fi
    done
fi


if [ ${#packages_to_ask[@]} -gt 0 ]; then
    echo "---------------------------------------------"
    echo "Please review the following packages:"
    # Loop through the packages we need to ask about.
    for package in "${packages_to_ask[@]}"; do
        if [ "$AUTO_YES" = true ]; then
            echo "Auto-selecting '$package' for upgrade."
            packages_to_upgrade+=("$package")
            continue
        fi

        # Determine the default prompt based on saved settings (if -i is used).
        prompt_default="n"
        prompt_options="y/N/a(lways)/w(hitelist)"

        if [ "$IGNORE_SETTINGS" = true ]; then
            if [[ " ${ALWAYS_YES_PKGS[*]} " =~ " ${package} " ]]; then
                prompt_default="a"
                prompt_options="y/n/A(lways)/w(hitelist)"
            elif [[ " ${ALWAYS_NO_PKGS[*]} " =~ " ${package} " ]]; then
                prompt_default="w"
                prompt_options="y/n/a(lways)/W(hitelist)"
            fi
        fi

        read -p "Upgrade '$package'? [$prompt_options] " choice < /dev/tty
        # If user just presses Enter, use the determined default.
        choice=${choice:-$prompt_default}

        case "$(echo "$choice" | tr '[:upper:]' '[:lower:]')" in
            y|yes)
                packages_to_upgrade+=("$package")
                echo "-> Queued '$package' for upgrade."
                ;;
            a|always)
                packages_to_upgrade+=("$package")
                update_setting "ALWAYS_YES" "$package"
                echo "-> Queued '$package' and saved preference as 'Always Yes'."
                ;;
            w|whitelist|ignore)
                update_setting "ALWAYS_NO" "$package"
                echo "-> Skipped '$package' and saved preference as 'Always No'."
                ;;
            *)
                echo "-> Skipped '$package'."
                ;;
        esac
    done
fi

echo "---------------------------------------------"

if [ ${#packages_to_upgrade[@]} -gt 0 ]; then
    echo "Preparing to upgrade the following selected packages:"
    printf " - %s\n" "${packages_to_upgrade[@]}"
    echo

    # Loop through each selected package and upgrade it individually.
    # This prevents one failed package from halting the entire process.
    for package in "${packages_to_upgrade[@]}"; do
        echo "--> Upgrading '$package'..."
        if yay -S --noconfirm "$package"; then
            echo "--> Successfully upgraded '$package'."
        else
            echo "--> FAILED to upgrade '$package'. Continuing with the next one."
        fi
        echo # Add a blank line for readability between packages
    done
else
    echo "No packages were selected for upgrade."
fi

echo "---------------------------------------------"
echo "Selective upgrade process complete."

