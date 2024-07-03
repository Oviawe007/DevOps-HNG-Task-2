
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
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run with root privileges." >&2
  exit 1
fi



# Define file paths
user_file="$1"  # Assigns the first argument (user list file path) to user_file variable
log_file="/var/log/user_management.log"
password_file="/var/secure/user_passwords.txt"



# Check if user list file path is provided as argument
if [ $# -ne 1 ]; then
  echo "Usage: $0 <user_list_file>" >&2
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
    usermod -a -G "$group" "$username" &>> "$log_file"
  done

  # Generate random password (using here-document)
  password=$(<<EOF
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
  message="$1"
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $message" >> "$log_file"
}

# Check if user list file exists
if [ ! -f "$user_file" ]; then
  echo "User list file '$user_file' not found. Please check the path." >&2
  exit 1
fi

# Loop through users in the list file
while IFS= read -r username groups; do
  create_user "$username" "$groups"
done < "$user_file"

echo "User creation completed. Please refer to the log file for details: $log_file"
