#!/usr/bin/env bash

set -eux

DISTRIB_ID="cumulus-linux"
DISTRIB_CODENAME="4.4.0"
DISTRIB_SHA256="183cd61e8adece8e97163eccc0ab4faf4314c896639b8b8ac28c93074fecf7b2"

PVE_TMP_VMID="9002"
PVE_VOLUME="cephrbd01"
PVE_NET0_VLAN="221"
PVE_USERNAME="naa0yama"

mkdir -p "${DISTRIB_ID}/${DISTRIB_CODENAME}"
cd "${DISTRIB_ID}/${DISTRIB_CODENAME}"

if ! [ -f "cumulus-linux-${DISTRIB_CODENAME}-vx-amd64-qemu_edited.qcow2" ]; then
    wget -c "https://d2cd9e7ca6hntp.cloudfront.net/public/CumulusLinux-${DISTRIB_CODENAME}/cumulus-linux-${DISTRIB_CODENAME}-vx-amd64-qemu.qcow2"
    cat "${DISTRIB_SHA256}" | sha256sum -c -
    mv "cumulus-linux-${DISTRIB_CODENAME}-vx-amd64-qemu.qcow2" "cumulus-linux-${DISTRIB_CODENAME}-vx-amd64-qemu_edited.qcow2"
fi

qm create "${PVE_TMP_VMID}" --name "cumulus-linux-${DISTRIB_CODENAME}-vx-amd64" --cores 2 --memory 2048 --net0 virtio,bridge=vmbr0,tag="${PVE_NET0_VLAN}"
qm importdisk "${PVE_TMP_VMID}" "cumulus-linux-${DISTRIB_CODENAME}-vx-amd64-qemu_edited.qcow2" "${PVE_VOLUME}"
qm set "${PVE_TMP_VMID}" --scsihw lsi --scsi0 "${PVE_VOLUME}:vm-${PVE_TMP_VMID}-disk-0"
qm set "${PVE_TMP_VMID}" --boot c --bootdisk scsi0
qm set "${PVE_TMP_VMID}" --ostype l26
qm set "${PVE_TMP_VMID}" --agent enabled=1,fstrim_cloned_disks=1
qm template "${PVE_TMP_VMID}"
