#!/bin/bash

# Author : Efosa Oviawe
# Description: This Bash script automates user creation, group management, and password generation for new employees based on a user list file
# Date: 30/06/2024

#############################################################

########### HOW TO USE ###########################


# 1. Create a text file (e.g., user_list.txt) containing user information in the format username;groups (one user per line).
# 2. Make the script executable: chmod +x create_users.sh
# 3. Run the script: sudo ./create_users.sh user_list.txt


###########################################################

# Ensure script is run with root privileges
if [[ "$(id -u)" -ne 0 ]]; then
  echo "This script must be run with root or sudo privileges." >&2
  log "Script not run as root or with sudo privileges"
  exit 1
fi

# Check if user list file path is provided as argument
if [ $# -ne 1 ]; then
  echo "Usage: $0 <USER_LIST_FILE>" >&2
  exit 1
fi

# Define file paths in uppercase
USER_FILE="$1"  # Assigns the first argument (user list file path) to USER_FILE variable
LOG_FILE="/var/log/USER_MANAGEMENT.LOG"
PASSWORD_FILE="/var/secure/USER_PASSWORDS.TXT"

# Check if user list file exists
if [ ! -f "$USER_FILE" ]; then
  echo "User list file '$USER_FILE' not found. Please check the path." >&2
  exit 1
fi

# Function to create user, group, set permissions, and log actions
create_user() {
  username="$1"
  groups="$2"

  log_message "Creating user: $username"

  # Check if user already exists
  if id "$username" >/dev/null 2>&1; then
    log_message "User $username already exists. Skipping..."
    return 1
  fi

  # Create user group
  groupadd "$username" &>> "$LOG_FILE"

  # Create user with home directory
  useradd -m -g "$username" "$username" &>> "$LOG_FILE"

  # Set home directory permissions
  chown -R "$username:$username" "/home/$username" &>> "$LOG_FILE"
  chmod 700 "/home/$username" &>> "$LOG_FILE"

  # Add user to additional groups (if any)
  for group in $(echo "$groups" | tr ',' ' '); do
    if ! grep -q "^$group:" /etc/group; then
      groupadd "$group" &>> "$LOG_FILE"
    fi
    usermod -a -G "$group" "$username" &>> "$LOG_FILE"
  done

  # Generate random password (using here-document)
  password=$(<<EOF
  </dev/urandom
  tr -dc A-Za-z0-9!@#$%^&*()
  head -c16
  EOF
  )

  echo "$username:$password" >> "$PASSWORD_FILE"
  chmod 600 "$PASSWORD_FILE" &>> "$LOG_FILE"

  # Set user password
  echo "$password" | passwd --stdin "$username" &>> "$LOG_FILE"

  log_message "User $username created successfully."
}

# Function to log messages with timestamps
log_message() {
  message="$1"
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $message" >> "$LOG_FILE"
}

# Loop through users in the list file
while IFS= read -r username groups; do
  create_user "$username" "$groups"
done < "$USER_FILE"

echo "User creation completed. Please refer to the log file for details: $LOG_FILE"
