#!/bin/bash

# Check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to remove "http://" or "https://" from the URL
remove_http_prefix() {
  echo "$1" | sed 's~^https\?://~~'
}

# Function to replace slashes with underscores in the directory name
replace_slashes() {
  echo "$1" | sed 's~/~_~g'
}

# Check if httrack and ipfs are installed
if ! command_exists httrack || ! command_exists ipfs; then
  missing_bins=""
  if ! command_exists httrack; then
    missing_bins+="httrack "
  fi
  if ! command_exists ipfs; then
    missing_bins+="ipfs"
  fi

  echo "Error: This script requires the following command(s) to be installed and added to your system's PATH: $missing_bins"
  exit 1
fi


echo "Welcome mimic IPFS Publisher Wizard!"

# Define the full path to the log file
log_file="$PWD/published_websites.log"

# Create the log file if it doesn't exist
if [[ ! -e "$log_file" ]]; then
  touch "$log_file"
fi

# Get the website URL from the user
echo "Please enter the website URL you want to publish on IPFS:"
read -p "Website URL: " website_url

# Check if the website is already published
existing_entry=$(grep -A 3 "Website URL: $website_url" $log_file)
if [[ -n "$existing_entry" ]]; then
  existing_website_dir=$(echo "$existing_entry" | sed -n '1s/Website URL: //p')
  existing_ipfs_path=$(echo "$existing_entry" | sed -n '2s/IPFS Path: //p')

  echo "The website is already published on IPFS with path: $existing_ipfs_path"
  echo "Do you want to update the website? (yes/no)"
  read update_choice

  if [[ "$update_choice" == "yes" ]]; then
    echo "Updating the website..."
    cd "$existing_website_dir" || exit 1
    httrack --update
    cd - || exit 1
    echo "Website update completed!"
    # Correctly set the IPFS path for publishing
    ipfs_path=$(ipfs add -rQ "$existing_website_dir")
    echo "Website updated and published to IPFS. New IPFS path: $ipfs_path"

  else
    echo "Exiting the script without updating the website."
    exit 0
  fi
else
  # Extract the base name from the website URL to use as the directory name
  website_dir=$(remove_http_prefix "$website_url")
  website_dir=$(replace_slashes "$website_dir")

  # Download the website using httrack
  echo "Downloading the website..."
  httrack --mirror --robots=0 --stay-on-same-domain --user-agent "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:63.0) Gecko/20100101 Firefox/63.0" --keep-links=0 --path "./$website_dir" --quiet "$website_url" -* +$website_url/*
  echo "Download completed!"

  # Publish the website to IPFS
  echo "Publishing the website to IPFS..."
  ipfs_path=$(ipfs add -rQ "./$website_dir")
  echo "Website published to IPFS. IPFS path: $ipfs_path"

  # Log the website URL, IPFS path, and publication time for new publication
  publication_time=$(date "+%Y-%m-%d %H:%M:%S")
  echo "Website URL: $website_url" >> $log_file
  echo "IPFS Path: $ipfs_path" >> $log_file
  echo "Last Update: $publication_time" >> $log_file
fi

# Ask the user if they want to publish the IPFS path to an IPNS address
echo "Do you want to publish the latest IPFS path to an IPNS address? (yes/no)"
read publish_ipns_choice

if [[ "$publish_ipns_choice" == "yes" ]]; then
  # Check if an IPNS key exists for the website
  if [[ -n "$existing_ipns_key" ]]; then
    echo "An IPNS key is already associated with this website: $existing_ipns_key"
    echo "Do you want to use the existing IPNS key, use your own key, or generate a new one? (existing/own/new)"
    read ipns_key_choice

    if [[ "$ipns_key_choice" == "existing" ]]; then
      # Publish to IPNS using the existing key
      echo "Publishing to IPNS using the existing key..."
      ipns_path=$(ipfs name publish --key="$existing_ipns_key" "$ipfs_path")
      echo "Website published to IPNS. IPNS path: $ipns_path"

      # Log the IPNS address and update time in the log file
      update_time=$(date "+%Y-%m-%d %H:%M:%S")
      echo "IPNS Path: $ipns_path" >> $log_file
      echo "Last Update: $update_time" >> $log_file
    elif [[ "$ipns_key_choice" == "own" ]]; then
      # Use user's existing IPNS key
      echo "Please enter your existing IPNS key name:"
      read existing_ipns_key_name

      # Check if the existing IPNS key name is valid
      existing_key_names=$(ipfs key list -l | awk '{print $1}')
      if [[ "$existing_key_names" =~ (^|[[:space:]])"$existing_ipns_key_name"($|[[:space:]]) ]]; then
        ipns_path=$(ipfs name publish --key="$existing_ipns_key_name" "$ipfs_path")
        echo "Website published to IPNS. IPNS path: $ipns_path"

        # Log the IPNS address and update time in the log file
        update_time=$(date "+%Y-%m-%d %H:%M:%S")
        echo "IPNS Path: $ipns_path" >> $log_file
        echo "Last Update: $update_time" >> $log_file
      else
        echo "Error: The provided IPNS key name does not exist."
        exit 1
      fi
    elif [[ "$ipns_key_choice" == "new" ]]; then
      # Generate a new IPNS key if the user chooses to generate a new key
      echo "Please enter a name for the new IPNS key:"
      read new_key_name

      # Check if the new key name already exists
      existing_key_names=$(ipfs key list -l | awk '{print $1}')
      if [[ "$existing_key_names" =~ (^|[[:space:]])"$new_key_name"($|[[:space:]]) ]]; then
        echo "Error: A key with the name '$new_key_name' already exists. Please choose a different name."
        exit 1
      fi

      # Generate and publish to IPNS using the new key
      echo "Generating and publishing to IPNS using the new key..."
      ipfs key gen --type=rsa --size=2048 "$new_key_name"
      ipns_path=$(ipfs name publish --key="$new_key_name" "$ipfs_path")
      echo "Website published to IPNS with the new key. IPNS path: $ipns_path"

      # Log the IPNS address, key name, and update time in the log file
      update_time=$(date "+%Y-%m-%d %H:%M:%S")
      echo "IPNS Path: $ipns_path" >> $log_file
      echo "IPNS Key: $new_key_name" >> $log_file
      echo "Last Update: $update_time" >> $log_file
    else
      echo "Invalid choice. Skipping IPNS publishing."
    fi
  else
    # Generate a new IPNS key if an IPNS key doesn't exist
    echo "Please enter a name for the new IPNS key:"
    read new_key_name

    # Check if the new key name already exists (needs testing)
    existing_key_names=$(ipfs key list -l | awk '{print $1}')
    for key_name in $existing_key_names; do
      if [[ "$key_name" == "$new_key_name" ]]; then
        echo "Error: A key with the name '$new_key_name' already exists. Please choose a different name."
        exit 1
      fi
    done


    # Generate and publish to IPNS using the new key
    echo "Generating and publishing to IPNS using the new key..."
    ipfs key gen --type=rsa --size=2048 "$new_key_name"
    ipns_path=$(ipfs name publish --key="$new_key_name" "$ipfs_path")
    echo "Website published to IPNS with the new key. IPNS path: $ipns_path"

    # Log the IPNS address, key name, and update time in the log file
    update_time=$(date "+%Y-%m-%d %H:%M:%S")
    echo "IPNS Path: $ipns_path" >> $log_file
    echo "IPNS Key: $new_key_name" >> $log_file
    echo "Last Update: $update_time" >> $log_file
  fi
fi

# Exit
echo "The website is now published on IPFS. Exiting."
exit 0