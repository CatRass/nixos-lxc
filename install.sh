#!/bin/bash

# Make the directory
mkdir -p /opt/nixos-lxc

# Get nix config file
curl -fsSL -o /opt/nixos-lxc/configuration.nix https://raw.githubusercontent.com/CatRass/nixos-lxc/refs/heads/main/configuration.nix

# Get the environment file
curl -fsSL -o /opt/nixos-lxc/lxc.env https://raw.githubusercontent.com/CatRass/nixos-lxc/refs/heads/main/lxc.env

read -p 'Start installation straight away? (Y/n) ' immediateInstall

if [[ ${immediateInstall} == [yY] || -z ${immediateInstall} ]]; then
  echo "Starting install..."
  curl -fsSL -o /opt/nixos-lxc/create.sh https://raw.githubusercontent.com/CatRass/nixos-lxc/refs/heads/main/script.sh
  cd /opt/nixos-lxc
  bash ./create.sh
elif [[ ${immediateInstall} == [nN] ]]; then
  echo "Downlaoding and exiting..."
  curl -fsSL -o /opt/nixos-lxc/create.sh https://raw.githubusercontent.com/CatRass/nixos-lxc/refs/heads/main/script.sh
fi