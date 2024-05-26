# Backup Manager

## Description

`backupManager.sh` is a Bash script designed to manage backups for various local and remote
resources. The script provides options to backup specific directories, sync backups, and run all
backup tasks. It also includes a test mode to simulate the backup process with sample data.

## Features

- Backup specific directories from local and remote servers
- Synchronize local backups with a remote server
- Run all backup tasks in a single command
- Test mode to simulate backups with sample data

## Requirements

- Bash
- rsync
- ssh
- sudo

## Installation

1. Clone the repository:

```bash
git clone https://github.com/TituxMetal/backupManager.git
cd backupManager
```

2. Make the script executable:

```bash
chmod +x backupManager.sh
```

## Usage

### Normal Mode

To run the script in normal mode, simply execute:

```bash
./backupManager.sh
```

### Test Mode

To run the script in test mode, which sets up a test environment and simulates the backup process
with sample data, use the --test parameter:

```bash
./backupManager.sh --test
```

### Backup Tasks

When you run the script, you will be prompted to select a backup task:

1. **Backup local AllDataZ to homelab**
2. **Backup virt-manager**
3. **Backup all servers**
4. **Backup a specific server**
5. **Sync local backups with homelab**
6. **Run all backup tasks**

Select the appropriate option by entering the corresponding number.

## Configuration

### Servers

The script is configured to backup data from the following servers:

- **`andrew`**
- **`bart`**
- **`lisa`**
- **`laura`**
- **`mary`**
- **`homelab`**

You can modify the `SERVERS` array in the script to include or exclude servers as needed.

### Directories

The script backs up the following directories from each server:

- **`/home`**
- **`/srv`**
- **`/etc`**
- **`/var/lib/docker/volumes`**
- **`/var/log`**

You can modify the `directories` array in the `backupServers` function to include or exclude
directories as needed.

## Functions

`printMessage`

Prints a formatted message to the terminal.

`handleError`

Handles errors and exits the script if an error occurs.

`createDir`

Creates a directory.

`populateDir`

Populates a directory with sample data.

`setupTestEnvironment`

Sets up the test environment for the script by creating necessary directories and populating them
with sample data.

`backupAllDataZ`

Backs up all data from `localAllDataZ` to `remoteHomelabAllDataZ` using rsync.

`backupVirtManager`

Backs up the `virt-manager` directory using rsync.

`backupServers`

Backs up specified directories on a remote server using rsync.

`syncBackups`

Synchronizes backups from a local directory to a remote directory using rsync.

`selectBackupTask`

Displays a menu of backup tasks and performs the selected task based on user input.

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## Author

Titux Metal <tituxmetal[at]lgdweb[dot]fr>

## Acknowledgments

Special thanks to the open-source community for providing the tools and resources that made this
project possible.
