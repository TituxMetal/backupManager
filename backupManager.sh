#!/bin/bash

# Name: backupManager.sh
# Description: Manage backups for various local and remote resources.
# Author: Titux Metal <tituxmetal[at]lgdweb[dot]fr>
# Url: https://github.com/TituxMetal/backupManager
# Version: 1.0
# Revision: 2024.05.26
# License: MIT License

# Global variables
TEST_MODE=false
BASE_DIR=./testEnv
SERVERS=(andrew bart lisa laura mary homelab)

# Function to print a message with formatting
# Usage: printMessage <message>
# Arguments:
#   - message: The message to be printed
printMessage() {
  local message="$1"
  if [ -t 1 ]; then  # Check if output is a terminal
    tput setaf 2
    echo -en "-------------------------------------------\n"
    echo -en "${message}\n"
    echo -en "-------------------------------------------\n"
    tput sgr0
  else
    echo -en "-------------------------------------------\n"
    echo -en "${message}\n"
    echo -en "-------------------------------------------\n"
  fi
}

# Function to handle errors and exit the script if an error occurs.
# Parameters:
#   None
# Returns:
#   None
handleError() {
  local exitCode=$?
  if [ $exitCode -ne 0 ]; then
    printMessage "An error occurred with status: $exitCode"
    exit $exitCode
  fi
}

# Function to create a directory.
# Usage: createDir <directory_path>
#   <directory_path>: The path of the directory to be created.
createDir() {
  mkdir -pv "$1"
}

# Function to populate a directory with sample data
# Arguments:
#   $1: The name of the data
#   $2: The file to write the sample data to
populateDir() {
  local data="$1"
  local file="$2"
  echo "Sample data for $data" > "$file"
}

# Function to set up the test environment for the backupManager script.
# This function creates the necessary source and destination directories for each server,
# as well as populates them with sample files for testing purposes.
# It also creates the source and destination directories for backupAllDataZ and backupVirtManager,
# and populates them with sample files.
# Finally, it creates the destination directory for syncBackups.
# This function does not return any value.
setupTestEnvironment() {
  printMessage "Setting up test environment..."

  local serverDirs=("home" "srv" "etc" "var/lib/docker/volumes" "var/log")

  # Create source and destination directories for each server
  for server in ${SERVERS[@]}; do
    for dir in ${serverDirs[@]}; do
      # Create source test directories for backupServers
      createDir "$BASE_DIR/$server/$dir"
      # Create destination test directories for backupServers
      createDir "$BASE_DIR/media/local/Backup--timeshift/remote/$server/$dir"
      populateDir "/$server" "$BASE_DIR/$server/$dir/sample.txt"
    done

  done

  # Create source test directory for backupAllDataZ
  createDir "$BASE_DIR/media/local/AllDataZ--Local"
  # Create destination test directory for backupAllDataZ
  createDir "$BASE_DIR/homelab/media/local/AllDataZ"
  createDir "$BASE_DIR/homelab/media/local/AllDataZ/toBeDeleted"
  populateDir "/AllDataZ--Local" "$BASE_DIR/media/local/AllDataZ--Local/sample.txt"
  # Create source test direcory for backupVirtManager
  createDir "$BASE_DIR/home/titux/virt-manager"
  # Create destination test directory for backupVirtManager
  createDir "$BASE_DIR/media/local/Backup--timeshift/virt-manager"
  
  populateDir "/virt-manager" "$BASE_DIR/home/titux/virt-manager/sample.txt"
  # Create destination test directory for syncBackups
  createDir "$BASE_DIR/homelab/media/local/backup"


  printMessage "Test environment setup completed."
}

# Function to backup all data from localAllDataZ to remoteHomelabAllDataZ using rsync.
backupAllDataZ() {
  local localAllDataZ="/media/local/AllDataZ--Local"
  local remoteHomelabAllDataZ="supertux@homelab.local:/media/local/AllDataZ"
  local rsyncArgs=(-rltv --human-readable --progress --stats --delete --exclude='lost+found' --exclude='/**/*.cache/' --exclude='/**/*.next/' --exclude='/**/dist/' --exclude='/**/node_modules/')

  if [ "$TEST_MODE" = true ]; then
    localAllDataZ="$BASE_DIR/media/local/AllDataZ--Local"
    remoteHomelabAllDataZ="$BASE_DIR/homelab/media/local/AllDataZ"

    printMessage "Source in test mode check: $localAllDataZ"
    printMessage "Dest in test mode check: $remoteHomelabAllDataZ"
  fi

  rsync "${rsyncArgs[@]}" "$localAllDataZ/" "$remoteHomelabAllDataZ/"

  printMessage "Backup of AllDataZ completed successfully."
}

# Function to backup the virt-manager directory using rsync.
backupVirtManager() {
  # Directory path of the virt-manager directory
  local virtManagerDir="/home/titux/virt-manager"
  # Directory path where the backup will be stored
  local backupDir="/media/local/Backup--timeshift"
  # Arguments for the rsync command
  local rsyncArgs=(-rltv --human-readable --progress --stats --delete --exclude='lost+found')

  if [ "$TEST_MODE" = true ]; then
    # Directory path of the virt-manager directory in test mode
    virtManagerDir="$BASE_DIR/home/titux/virt-manager"
    # Directory path where the backup will be stored in test mode
    backupDir="$BASE_DIR/media/local/Backup--timeshift/virt-manager"

    printMessage "Source in test mode check: $virtManagerDir"
    printMessage "Dest in test mode check: $backupDir"
  fi

  # Perform the backup using rsync command
  rsync "${rsyncArgs[@]}" "$virtManagerDir/" "$backupDir/"

  printMessage "Backup of virt-manager completed successfully."
}

# Function to backup servers
# Parameters:
#   - serverName: The name of the server to backup
# Description:
#   This function performs a backup of specified directories on a remote server using rsync.
#   It creates the necessary directory structure on the backup destination and then performs
#   the rsync operation for each directory. If TEST_MODE is enabled, it uses a local directory
#   as the source and destination for testing purposes.
#   The function prints a success or failure message for each directory backup.
backupServers() {
  local serverName="$1"
  local fullServerName="supertux@${serverName}.lgdweb.ovh:"
  local backupBaseDir="/media/local/Backup--timeshift/remote/${serverName}"
  local rsyncArgs=(-rltv --human-readable --progress --stats --delete --exclude='/lost+found' --exclude '/**/system@*' --exclude '/**/letsencrypt' --exclude '/**/dummykey.pem')

  if [ "$TEST_MODE" = true ]; then
    fullServerName="$BASE_DIR/$serverName"
    backupBaseDir="$BASE_DIR/media/local/Backup--timeshift/remote/${serverName}"

    printMessage "Source in test mode check: $fullServerName"
    printMessage "Dest in test mode check: $backupBaseDir"
  fi

  # Directories to backup
  local directories=("/home" "/srv" "/var/log" "/etc" "/var/lib/docker/volumes")

  # Create the necessary directory structure
  for dir in "${directories[@]}"; do
    mkdir -pv "$backupBaseDir$dir"
  done

  # Perform the rsync operation for each directory using sudo on the remote side
  for dir in "${directories[@]}"; do
    if [ "$TEST_MODE" = true ]; then
      printMessage "Source in for loop: $fullServerName$dir/"
      printMessage "Dest in for loop: $backupBaseDir$dir/"
    fi

    rsync -e "ssh" "${rsyncArgs[@]}" --rsync-path="sudo rsync" "$fullServerName$dir/" "$backupBaseDir$dir/" \
    && printMessage "Backup of $dir from $serverName completed successfully." \
    || printMessage "Failed to backup $dir from $serverName."
  done
}

# Function to synchronize backups from a local directory to a remote directory.
syncBackups() {
  local localBackupDir="/media/local/Backup--timeshift"
  local remoteHomelabBackupDir="supertux@homelab.local:/media/local/backup"
  local rsyncArgs=(-rltv --human-readable --progress --stats --delete --exclude='lost+found' --exclude '/timeshift')
  #  local rsyncArgs=(-rltv --dry-run --human-readable --progress --stats --delete --exclude='lost+found' --exclude '/timeshift')

  if [ "$TEST_MODE" = true ]; then
    localBackupDir="$BASE_DIR/media/local/Backup--timeshift"
    remoteHomelabBackupDir="$BASE_DIR/homelab/media/local/backup"

    printMessage "Source in test mode check: $localBackupDir"
    printMessage "Dest in test mode check: $remoteHomelabBackupDir"
  fi

  rsync "${rsyncArgs[@]}" "$localBackupDir/" "$remoteHomelabBackupDir/"

  printMessage "Sync of local backups with homelab completed successfully."
}

# Function: selectBackupTask
# Description: Displays a menu of backup tasks and performs the selected task based on user input.
selectBackupTask() {
  local servers=("andrew" "bart" "lisa" "laura" "mary" "homelab")

  echo "1. Backup local AllDataZ to homelab"
  echo "2. Backup virt-manager"
  echo "3. Backup all servers"
  echo "4. Backup a specific server"
  echo "5. Sync local backups with homelab"
  echo "6. Run all backup tasks"
  read -p "Enter your choice: " choice

  case $choice in
    1) backupAllDataZ ;;
    2) backupVirtManager ;;
    3) for server in "${servers[@]}"; do
         backupServers $server
       done ;;
    4) 
       echo "Select the server to backup:"
       select serverName in "${servers[@]}"; do
         if [[ -n "$serverName" ]]; then
           backupServers "$serverName"
           break
         else
           echo "Invalid choice. Please select a valid server number."
         fi
       done ;;
    5) syncBackups ;;
    6)
       backupAllDataZ
       backupVirtManager
       for server in "${servers[@]}"; do
         backupServers $server
       done
       syncBackups ;;
    *) echo "Invalid choice"; exit 1 ;;
  esac
}

main() {
  trap 'handleError' ERR

  if [ "$1" == "--test" ]; then
    printMessage "Test mode enabled"
    TEST_MODE=true
    setupTestEnvironment
  fi

  printMessage "Backup Manager Initialized"

  selectBackupTask

  printMessage "Congratulations, all tasks completed successfully!"
}

time main "$@"

exit 0
