# Proxmox Script for creating NixOS LXC Containers

This script is based off the [NixOS ProxmoxVE LXC guide](https://nixos.wiki/wiki/Proxmox_Linux_Container). Currently it only installs NixOS 24.11.

## Using the script
In your Proxmox console, enter the following command:
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/CatRass/nixos-lxc/refs/heads/main/install.sh)"
```