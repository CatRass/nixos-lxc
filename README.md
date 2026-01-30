# Proxmox NixOS LXC Script
This script is based off the [NixOS ProxmoxVE LXC guide](https://nixos.wiki/wiki/Proxmox_Linux_Container). Currently it only installs NixOS 24.11.

## Using the script
> [!WARNING] 
> Before running this script, please be sure to check the source code. The source for the installer is viewable [here](./install.sh), and the LXC creation script [here](./src/script.sh)

In your Proxmox console, enter the following command:
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/CatRass/nixos-lxc/refs/heads/main/install.sh)"
```
> [!NOTE]
>To make changes to the current config, you will have to exit out of the installer when prompted

## Changing LXC Config
Currently, the LXC's configuration is changed through the [lxc.env](./src/lxc.env) file.

The supported parameters are:

|Parameter|Description|Default Value|Mandatory|
|-|-|-|-|
nixos_ctid|The LXC's ID|`100`|✔️|
nixos_ctname|The name of the LXC|`nixos-lxc`|✔️|
nixos_ctt|Location of the LXC template|`local:vztmpl/nixos-system.tar.xz`|✔️|
nixos_ctstorage|Default storage for the LXC|`local-lvm`|✔️|
nixos_ctip|The LXC container's IPv4 address|`dhcp`|✔️|
nixos_ctgw|The LXC container's default gateway|``|❌|
nixos_ram|The amount of RAM (MB) allocated to the LXC|`2048`|❌|
nixos_swap|The amount of swapspace (MB) allocated to the LXC|`1024`|❌|
nixos_cpu|The number of cores allocated to the LXC|`2`|❌|
nixos_autostart|Whether the container should start on proxmox boot|`1` (True)|❌|

For all missing non-mandatory parameter, a default value will be allocated

## Contributing
If you want to contribute to this repo, please feel free to! 

To to the code contribute:
1. Fork the repo
2. Open a branch with the format `feat/my-new-feature` (replacing `feat` for `docs`, `fix` etc.)
3. Make your changes
4. Open a Pull Request
5. Wait for me to approve!

You can also contribute by putting in a feature request through the Issues page. Any suggestions are welcome!

## Planned Features
- Fully guided install
- All possible options for `pct create` configurable
- Add password setting, as currently no root password is set