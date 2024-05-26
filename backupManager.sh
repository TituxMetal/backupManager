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

handleError() {
  local exitCode=$?
  if [ $exitCode -ne 0 ]; then
    printMessage "An error occurred with status: $exitCode"
    exit $exitCode
  fi
}

setupTestEnvironment() {
  printMessage "Setting up test environment..."

  # Create source test directories for backupServers
  mkdir -pv ~/test_env/{andrew,bart,lisa,laura,mary,homelab}/{home,srv,etc,var/lib/docker/volumes,var/log}
  #  Create destination test directories for backupServers
  mkdir -pv ~/test_env/media/local/Backup--timeshift/remote/{andrew,bart,lisa,laura,mary,homelab}
  #  Create source test directory for backupAllDataZ
  mkdir -pv ~/test_env/media/local/AllDataZ--Local
  #  Create destination test directory for backupAllDataZ
  mkdir -pv ~/test_env/homelab/media/local/AllDataZ
  mkdir -pv ~/test_env/homelab/media/local/AllDataZ/toBeDeleted
  #  Create source test direcory for backupVirtManager
  mkdir -pv ~/test_env/home/titux/virt-manager
  #  Create destination test directory for backupVirtManager
  mkdir -pv ~/test_env/media/local/Backup--timeshift/virt-manager
#  mkdir -pv ~/test_env/media/local/Backup--timeshift/virt-manager/{iso,disk}
  #  Create destination test directory for syncBackups
  mkdir -pv ~/test_env/homelab/media/local/backup


  printMessage "Populate test directories for servers with sample data"
  for server in andrew bart lisa laura mary homelab; do
    echo "Sample data for /home" > ~/test_env/$server/home/sample.txt
    echo "Sample data for /srv" > ~/test_env/$server/srv/sample.txt
    echo "Sample data for /etc" > ~/test_env/$server/etc/sample.txt
    echo "Sample data for /var/lib/docker/volumes" > ~/test_env/$server/var/lib/docker/volumes/sample.txt
    echo "Sample data for /var/log" > ~/test_env/$server/var/log/sample.txt
  done
  
  printMessage "Populate test directory for AllDataZ--Local with sample data"
  
  echo "Sample data for /AllDataZ--Local" > ~/test_env/media/local/AllDataZ--Local/sample.txt
  
  printMessage "Populate test data for AllDataZ with data to be deleted on dest"
  
  echo "Sample data to be deleted" > ~/test_env/homelab/media/local/AllDataZ/sample1.txt
  touch ~/test_env/homelab/media/local/AllDataZ/toBeDeleted/deleteMe
  
  printMessage "Populate test direcectory for virt-manager with sample data"

  echo "Sample data for /virt-manager" > ~/test_env/home/titux/virt-manager/sample.txt
#  touch ~/test_env/media/local/Backup--timeshift/virt-manager/{iso,disk}/deleteMe

  printMessage "Test environment setup completed."
}

backupAllDataZ() {
  local localAllDataZ="/media/local/AllDataZ--Local"
  local remoteHomelabAllDataZ="supertux@homelab.local:/media/local/AllDataZ"
  local rsyncArgs=(-rltv --human-readable --progress --stats --delete --exclude='lost+found' --exclude='/**/*.cache/' --exclude='/**/*.next/' --exclude='/**/dist/' --exclude='/**/node_modules/')
#  local rsyncArgs=(-rltv --dry-run --human-readable --progress --stats --delete --exclude='lost+found' --exclude='/**/*.cache/' --exclude='/**/*.next/' --exclude='/**/dist/' --exclude='/**/node_modules/')
  


  if [ "$TEST_MODE" = true ]; then
    localAllDataZ="$HOME/test_env/media/local/AllDataZ--Local"
    remoteHomelabAllDataZ="$HOME/test_env/homelab/media/local/AllDataZ"
  fi

  rsync "${rsyncArgs[@]}" "$localAllDataZ/" "$remoteHomelabAllDataZ/"

  printMessage "Backup of AllDataZ completed successfully."
}

backupVirtManager() {
  local virtManagerDir="/home/titux/virt-manager"
  local backupDir="/media/local/Backup--timeshift"
  local rsyncArgs=(-rltv --human-readable --progress --stats --delete --exclude='lost+found')
#  local rsyncArgs=(-rltv --dry-run --human-readable --progress --stats --delete --exclude='lost+found')

  if [ "$TEST_MODE" = true ]; then
    virtManagerDir="$HOME/test_env/home/titux/virt-manager"
    backupDir="$HOME/test_env/media/local/Backup--timeshift/virt-manager"
  fi

  rsync "${rsyncArgs[@]}" "$virtManagerDir/" "$backupDir/"

  printMessage "Backup of virt-manager completed successfully."
}

backupServers() {
  local serverName="$1"
  local fullServerName="supertux@${serverName}.lgdweb.ovh:"
  local backupBaseDir="/media/local/Backup--timeshift/remote/${serverName}"
  local rsyncArgs=(-rltv --human-readable --progress --stats --delete --exclude='/lost+found' --exclude '/**/system@*' --exclude '/**/letsencrypt' --exclude '/**/dummykey.pem')
  #  local rsyncArgs=(-rltv --dry-run --human-readable --progress --stats --delete --exclude='/lost+found' --exclude '/**/system@*' --exclude '/**/letsencrypt' --exclude '/**/dummykey.pem')

  if [ "$TEST_MODE" = true ]; then
    fullServerName="$HOME/test_env/$serverName"
    backupBaseDir="$HOME/test_env/media/local/Backup--timeshift/remote/${serverName}"

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

syncBackups() {
  local localBackupDir="/media/local/Backup--timeshift"
  local remoteHomelabBackupDir="supertux@homelab.local:/media/local/backup"
  local rsyncArgs=(-rltv --human-readable --progress --stats --delete --exclude='lost+found' --exclude '/timeshift')
  #  local rsyncArgs=(-rltv --dry-run --human-readable --progress --stats --delete --exclude='lost+found' --exclude '/timeshift')

  if [ "$TEST_MODE" = true ]; then
    localBackupDir="$HOME/test_env/media/local/Backup--timeshift"
    remoteHomelabBackupDir="$HOME/test_env/homelab/media/local/backup"
  fi

  rsync "${rsyncArgs[@]}" "$localBackupDir/" "$remoteHomelabBackupDir/"

  printMessage "Sync of local backups with homelab completed successfully."
}

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

