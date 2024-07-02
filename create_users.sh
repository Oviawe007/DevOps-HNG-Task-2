#!/bin/bash
# Author : Efosa Oviawe
# Description: This Bash script automates user creation, group management, and password generation for new employees based on a user list file
# Date: 30/06/2024

#############################################################

########### HOW TO USE ###########################


# 1. Create a text file (e.g., user_list.txt) containing user information in the format username;groups (one user per line).
# 2. Make the script executable: chmod +x create_users.sh
# 3. Run the script: sudo ./create_users.sh


###########################################################


#!/bin/bash
# Author : Efosa Oviawe
# Description: This Bash script automates user creation, group management, and password generation for new employees based on a user list file
# Date: 30/06/2024

#############################################################

########### HOW TO USE ###########################


# 1. Create a text file (e.g., user_list.txt) containing user information in the format username;groups (one user per line).
# 2. Make the script executable: chmod +x create_users.sh
# 3. Run the script: sudo ./create_users.sh


###########################################################


#!/bin/bash

# Ensure script is run with root privileges
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run with root privileges." >&2
  exit 1
fi

# Define file paths
user_file="/path/to/user_list.txt"
log_file="/var/log/user_management.log"
password_file="/var/secure/user_passwords.txt"

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
  groupadd "$username" &>> "$log_file"

  # Create user with home directory
  useradd -m -g "$username" "$username" &>> "$log_file"

  # Set home directory permissions
  chown -R "$username:$username" "/home/$username" &>> "$log_file"
  chmod 700 "/home/$username" &>> "$log_file"

  # Add user to additional groups (if any)
  for group in $(echo "$groups" | tr ',' ' '); do
    if ! grep -q "^$group:" /etc/group; then
      groupadd "$group" &>> "$log_file"
    fi
    usermod -a -G "$group" "$username" &>> "<span class="math-inline">log\_file"
done
\# Generate random password \(using here\-document\)
password\=</span>(<<EOF
</dev/urandom
tr -dc A-Za-z0-9!@#$%^&*()
head -c16
EOF
)

  echo "$username:$password" >> "$password_file"
  chmod 600 "$password_file" &>> "$log_file"

  # Set user password
  echo "$password" | passwd --stdin "$username" &>> "$log_file"

  log_message "User $username created successfully."
}

# Function to log messages with timestamps
log_message() {
  message="<span class="math-inline">1"
echo "</span>(date +'%Y-%m-%d %H:%M:%S') - $message" >> "$log_file"
}

# Check if user list
