#!/bin/bash
installDir="/opt/nixos-lxc"
nixConfigFile="${installDir}/configuration.nix"
envFile="${installDir}/lxc.env"

# Make the directory
echo "  Making directory to store script..."
mkdir -p /opt/nixos-lxc

# Get nix config file
echo "  Downloading Nix Config..."
curl -fsSL -o ${nixConfigFile} https://raw.githubusercontent.com/CatRass/nixos-lxc/refs/heads/main/src/configuration.nix
read -p 'Edit Nix Config? (Y/n) ' immediateNixConfig
if [[ ${immediateNixConfig} == [yY] || -z ${immediateNixConfig} ]]; then
  nano ${nixConfigFile}
fi
echo "Editing file: $nixConfigFile"

# Get the environment file
echo "  Downloading environment file..."
curl -fsSL -o ${envFile} https://raw.githubusercontent.com/CatRass/nixos-lxc/refs/heads/main/src/lxc.env
read -p 'Edit Env File? (Y/n) ' immediateEnvConfig
if [[ ${immediateEnvConfig} == [yY] || -z ${immediateEnvConfig} ]]; then
  nano ${envFile}
fi

read -p 'Start installation straight away? (Y/n) ' immediateInstall

if [[ ${immediateInstall} == [yY] || -z ${immediateInstall} ]]; then
  echo "  Starting install..."
  curl -fsSL -o /opt/nixos-lxc/create.sh https://raw.githubusercontent.com/CatRass/nixos-lxc/refs/heads/main/src/script.sh
  cd /opt/nixos-lxc
  bash ./create.sh
elif [[ ${immediateInstall} == [nN] ]]; then
  echo "  Downlaoding and exiting..."
  curl -fsSL -o /opt/nixos-lxc/create.sh https://raw.githubusercontent.com/CatRass/nixos-lxc/refs/heads/main/src/script.sh
  echo "  To install, run 'bash /opt/nixos-lxc/create.sh'"
  echo "  To make changes to the NixOS config, edit '${nixConfigFile}'"
  echo "  To make changes to the LXC's config, edit '${envFile}'"
fi