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

deleteUnfinishedLXC() {
  local lxcID=$1
  local shutdown=${$2:-false}
  if $shutdown; then
    pct shutdown ${lxcID}
  fi
  pct destroy ${lxcID}
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

if [ ! -e "/opt/nixos-lxc/rerun.tmp" ]; then

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
  lxcStats=`cat << EOF
  Creating NixOS LXC '${ctname}':
    - ID: ${ctid}
    - Cores: ${ctcpu}
    - RAM: ${ctram}
    - SWAP: ${ctswap}
    - Auto Start: ${ctstart}`
  echo "${lxcStats}"

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

  # Resize File System
  echo "Resizing File System . . ."
  lxcResize=$(pct resize ${ctid} rootfs +2G 2>&1)

  export lxcResizeError=$?
  if [ "$lxcResizeError" != "0" ]; then
      echo "  Error: Unable to resize LXC, reason: \"${lxcResize}\""
      echo "  Deleting LXC..."
      deleteUnfinishedLXC ${ctid}
      exit 1
  fi

  # Start the LXC
  echo "Starting LXC . . ."
  lxcStart=$(pct start ${ctid} 2>&1)

  export lxcStartError=$?
  if [ "$lxcStartError" != "0" ]; then
      echo "  Error: Unable to start LXC, reason: \"${lxcStart}\""
      echo "  Deleting LXC..."
      deleteUnfinishedLXC ${ctid}
      exit 1
  fi

  # Remove password
  pct exec ${ctid} -- sh -c "source /etc/set-environment && passwd --delete root"
fi

# Get NixOS Updates
echo "Updating NixOS . . ."
nixosUpdate=$(pct exec ${ctid} -- sh -c "source /etc/set-environment && nix-channel --update" 2>&1)

export nixosUpdateError=$?
if [ "$nixosUpdateError" != "0" ]; then
    echo "  Error: Unable to update NixOS LXC, reason: \"${nixosUpdate}\""
    exit 1
fi

# Move NixOS config from this directory to the lxc
pct push ${ctid} /opt/nixos-lxc/configuration.nix /etc/nixos/configuration.nix

# Build the nixos from config
echo "Rebuilding NixOS with Config . . ."
nixosBuild=$(pct exec ${ctid} -- sh -c "source /etc/set-environment && nixos-rebuild switch --upgrade" 2>&1)

export nixosBuildError=$?
if [ "$nixosBuildError" != "0" ]; then
    echo "  Error: Unable to build NixOS Config, reason: \"${nixosBuild}\""
    echo "  To re-attempt the install, please re-run this script with 'bash /opt/nixos-lxc/create.sh'"
    touch /opt/nixos-lxc/rerun.tmp
    exit 1
else
  rm -f /opt/nixos-lxc/rerun.tmp
fi

# clean up environmnet
cleanupEnv