#!/usr/bin/env bash

###
## This mounts a (single) ephemral NVMe drive in an EC2 server.
## It's meant to be run once, within user-data - it's idempotent
## For EBS drives (non-ephemeral storage), see: https://gist.github.com/jalaziz/c22c8464cb602bc2b8d0a339b013a9c4
#

# Install the "nvme" command
# See: https://github.com/linux-nvme/nvme-cli
sudo apt-get install -y nvme-cli

# Create a mount point (directory)
sudo mkdir -p /nvme

# Find ephemeral storage (assumes a single ephemeral disk)
# and format it (assumes this is run on first-boot in user-data, so the disk is not formatted)
EPHEMERAL_DISK=$(sudo nvme list | grep 'Amazon EC2 NVMe Instance Storage' | awk '{ print $1 }')
sudo mkfs.ext4 $EPHEMERAL_DISK
sudo mount -t ext4 $EPHEMERAL_DISK /nvme

### For some crazy reason, add ephemeral disk mount to /etc/fstab
## even tho you lose data in stop/starts of ec2 (I believe you keep the data via regular reboots?)
#
# Find the mounted drive UUID so we can mount by UUID
EPHEMERAL_UUID=$(sudo blkid -s UUID -o value $EPHEMERAL_DISK)

FSTAB_ENTRY="UUID=$EPHEMERAL_UUID /nvme ext4 defaults 0 0"

if grep -q "nvme" /etc/fstab; then
    sudo sed -i "/nvme/c\\$FSTAB_ENTRY" /etc/fstab
else
    echo "$FSTAB_ENTRY" | sudo tee -a /etc/fstab
