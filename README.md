# Arch Linux Automated Install

This repository contains a set of scripts designed to automate the installation of Arch Linux with LUKS encryption, along with additional configurations and package installations.

## Features

- **Automated Installation**: Streamline the setup of Arch Linux with minimal user intervention.
- **LUKS Encryption**: Secure your installation with full-disk encryption.
- **WiFi Support**: Connect to a WiFi network during installation.
- **Verbose Mode**: Get detailed output during the installation process.
- **Custom Configuration**: Set your timezone, hostname, username, and passwords.
- **Post-Installation Configuration**: Run custom root commands after installation.

## Structure

- `lists/`: This folder contains several lists used by the installation script:
  - `aur`: Git URLs of AUR repositories to be installed after setting up the system.
  - `hooks`: List of Initramfs hooks.
  - `modules`: List of Initramfs modules.
  - `packages`: List of pacman packages to be installed into the system.
- `post-install.sh`: A script that runs a series of root commands after installing and configuring the system.

## Usage

The installation script supports the following arguments:

| Short | Long            | Description                           | Mandatory |
|-------|-----------------|---------------------------------------|:---------:|
| `-h`  | `--help`        | Display help message                  |           |
| `-v`  | `--verbose`     | Enable verbose mode                   |           |
| `-S`  | `--ssid`        | WiFi SSID to connect                  |           |
| `-P`  | `--passphrase`  | WiFi Passphrase                       |           |
| `-I`  | `--interface`   | WiFi interface (default: wlan0)       |           |
| `-W`  | `--wifi`        | Connects to WiFi network              |           |
| `-D`  | `--disk`        | Disk to install Arch into             | Yes       |
| `-L`  | `--luks-password`| Disk encryption Password             | Yes       |
| `-R`  | `--reboot`      | Reboot when install script finishes   |           |
| `-T`  | `--time`        | Sets system TimeZone                  |           |
| `-U`  | `--username`    | Sets system Username                  | Yes       |
| `-p`  | `--password`    | Sets User and Root password           | Yes       |
| `-H`  | `--hostname`    | Sets system Hostname                  | Yes       |

### Example Command

```sh
./arch-install.sh --verbose -D sda -L "SuperStrongPassword" -T Europe/Berlin -U archiso -p testtest -H archiso-host
```

## Installation Steps

The script will perform the following steps:

1. Partition the disk.
2. Set up LUKS encryption.
3. Install the base system.
4. Configure the system (hostname, timezone, etc.).
5. Set up the bootloader.
6. Execute `post-install.sh` to apply additional configurations.
7. Reboot into your new Arch Linux system.

## Contributing

Contributions to this project are welcome. Please ensure that your pull requests are well-documented.

## License

This project is licensed under the AGPLv3 License - see the [LICENSE](LICENSE) file for details.

## Disclaimer

This script is provided as-is, and the authors are not responsible for any loss of data or damage that may occur. Please use it at your own risk.
