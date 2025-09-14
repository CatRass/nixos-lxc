#!/bin/bash

validateRequiredEnv() {
  if [[ -z ${ctid} || -z ${ctname} || -z ${ctt} || -z ${cts} ]]; then
    echo 1
  fi
}

cleanupEnv() {
  unset nixos_ctid
  unset nixos_ctname
  unset nixos_ctt
  unset nixos_storage
  unset nixos_ram
  unset nixos_cpu
  unset nixos_swap
  unset nixos_autostart
}


clear

echo "Loading environment variables . . ."
export $(cat /opt/nixos-lxc/lxc.env | xargs) 2> /dev/null

# Required LXC details
ctid=${nixos_ctid}
ctname=${nixos_ctname}
ctt=${nixos_ctt}
cts=${nixos_ctstorage}

if [[ $(validateRequiredEnv) -eq 1 ]]; then
  echo "  Error: Some essential environment variables are missing."
  exit 1
else
  echo "  Required environment variables loaded"
fi

# LXC Specs
ctram=${nixos_ram:-2048}
ctcpu=${nixos_cpu:-2}
ctswap=${nixos_swap:-1024}
ctstart=${nixos_autostart:-1}

# Download the image
echo "Downloading latest 24.11 LXC template . . ."
wget -O /var/lib/vz/template/cache/nixos-system.tar.xz \
  --no-verbose \
  https://hydra.nixos.org/job/nixos/release-24.11/nixos.proxmoxLXC.x86_64-linux/latest/download-by-type/file/system-tarball

export imageDownloadError=$?
if [ "$imageDownloadError" != "0" ]; then
    echo "  Error: Unable to download NixOS template"
    exit 1
fi

# Create the LXC
lxcCreate=$(pct create ${ctid} ${ctt} \
  --hostname=${ctname} \
  --ostype=nixos --unprivileged=0 --features nesting=1 --start=${ctstart}\
  --net0 name=eth0,bridge=vmbr0,ip=dhcp \
  --arch=amd64 --swap=${ctswap} --memory=${ctram} \
  --cores=${ctcpu} \
  --storage=${cts} \
  2>&1)

export lxcCreateError=$?
if [ "$lxcCreateError" != "0" ]; then
    echo "  Error: Unable to create LXC, reason: \"${lxcCreate}\""
    exit 1
fi

# Change some thingies
pct resize ${ctid} rootfs +2G

# Start the LXC
pct start ${ctid}

# Move config from this directory to the lxc
pct push ${ctid} /opt/nixos-lxc/configuration.nix /etc/nixos/configuration.nix

# Remove password
pct exec ${ctid} -- sh -c "source /etc/set-environment && passwd --delete root"

# Build the nixos from config
pct exec ${ctid} -- sh -c "source /etc/set-environment && nix-channel --update"
pct exec ${ctid} -- sh -c "source /etc/set-environment && nixos-rebuild switch --upgrade"

# clean up environmnet
cleanupEnv