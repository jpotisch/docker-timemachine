#!/bin/sh
# This script creates a macvlan network to place the docker container
# directly on the host network. This allows services to be broadcast
# so the TimeMachine host shows up in Finder without needing to run
# -net=host, which can conflict with host & introduce security issues.
#
# Step 1: Get vars from .env file
export $(grep -v '^#' .env | xargs)

# Step 2: Create network if not already present
if ! docker network list | grep macvlan ; then \
  docker network create \
    -d macvlan \
    --subnet=$TM_SUBNET/24 \
    --gateway=$TM_GATEWAY \
    -o parent=eth0 macvlan1
fi

# Step 3: Create and start docker container if not already present
if ! docker ps | grep timemachine ; then \
  docker run -d --restart=always \
    --name timemachine \
    --hostname timemachine \
    --network macvlan1 \
    --ip $TM_IP_ADDRESS \
    -p 137:137/udp \
    -p 138:138/udp \
    -p 139:139 \
    -p 445:445 \
    -e ADVERTISED_HOSTNAME="TimeMachine" \
    -e CUSTOM_SMB_CONF="false" \
    -e CUSTOM_USER="false" \
    -e DEBUG_LEVEL="1" \
    -e HIDE_SHARES="no" \
    -e EXTERNAL_CONF="" \
    -e MIMIC_MODEL="TimeCapsule8,119" \
    -e TM_USERNAME="timemachine" \
    -e TM_GROUPNAME="timemachine" \
    -e TM_UID="1000" \
    -e TM_GID="1000" \
    -e PASSWORD="$TM_PASSWORD" \
    -e SET_PERMISSIONS="false" \
    -e SHARE_NAME="Backups" \
    -e SMB_INHERIT_PERMISSIONS="no" \
    -e SMB_NFS_ACES="yes" \
    -e SMB_METADATA="stream" \
    -e SMB_PORT="445" \
    -e SMB_VFS_OBJECTS="acl_xattr fruit streams_xattr" \
    -e VOLUME_SIZE_LIMIT="0" \
    -e WORKGROUP="WORKGROUP" \
    -v $TM_BACKUP_PATH:/opt/timemachine \
    -v timemachine-var-lib-samba:/var/lib/samba \
    -v timemachine-var-cache-samba:/var/cache/samba \
    -v timemachine-run-samba:/run/samba \
    mbentley/timemachine:smb
fi
