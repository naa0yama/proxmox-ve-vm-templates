#!/usr/bin/env bash

set -eux

DISTRIB_ID=centos
DISTRIB_CODENAME=7
DISTRIB_VERSION=2009

PVE_TMP_VMID=9021
PVE_VOLUME=cephrbd01
PVE_NET0_VLAN=221
PVE_USERNAME=naa0yama

mkdir -p "${DISTRIB_ID}/${DISTRIB_CODENAME}"
cd "${DISTRIB_ID}/${DISTRIB_CODENAME}"

if ! [ -f "CentOS-${DISTRIB_CODENAME}-x86_64-GenericCloud-${DISTRIB_VERSION}_edited.qcow2" ]; then
    wget -c "https://cloud.centos.org/centos/${DISTRIB_CODENAME}/images/CentOS-${DISTRIB_CODENAME}-x86_64-GenericCloud-${DISTRIB_VERSION}.qcow2c"
    wget -c "https://cloud.centos.org/centos/${DISTRIB_CODENAME}/images/sha256sum.txt"
    grep -e "CentOS-${DISTRIB_CODENAME}-x86_64-GenericCloud-${DISTRIB_VERSION}.qcow2c" "sha256sum.txt" | sha256sum -c -

    qemu-img convert -f qcow2 -O qcow2 "CentOS-${DISTRIB_CODENAME}-x86_64-GenericCloud-${DISTRIB_VERSION}.qcow2c" "CentOS-${DISTRIB_CODENAME}-x86_64-GenericCloud-${DISTRIB_VERSION}_edited.qcow2"
    rm "CentOS-${DISTRIB_CODENAME}-x86_64-GenericCloud-${DISTRIB_VERSION}.qcow2c"
fi

virt-copy-in -a "CentOS-${DISTRIB_CODENAME}-x86_64-GenericCloud-${DISTRIB_VERSION}_edited.qcow2" ../../11_template.cfg /etc/cloud/cloud.cfg.d/
virt-ls -a "CentOS-${DISTRIB_CODENAME}-x86_64-GenericCloud-${DISTRIB_VERSION}_edited.qcow2" /etc/cloud/cloud.cfg.d/


qm create "${PVE_TMP_VMID}" --name "CentOS-${DISTRIB_CODENAME}-${DISTRIB_VERSION}" --cores 2 --memory 2048 --net0 virtio,bridge=vmbr0,tag="${PVE_NET0_VLAN}"
qm importdisk "${PVE_TMP_VMID}" "CentOS-${DISTRIB_CODENAME}-x86_64-GenericCloud-${DISTRIB_VERSION}_edited.qcow2" "${PVE_VOLUME}"
qm set "${PVE_TMP_VMID}" --scsihw virtio-scsi-pci --scsi0 "${PVE_VOLUME}:vm-${PVE_TMP_VMID}-disk-0"
qm set "${PVE_TMP_VMID}" --ide2 "${PVE_VOLUME}:cloudinit"
qm set "${PVE_TMP_VMID}" --boot c --bootdisk scsi0
qm set "${PVE_TMP_VMID}" --serial0 socket --vga serial0
qm set "${PVE_TMP_VMID}" --ostype l26
qm set "${PVE_TMP_VMID}" --agent enabled=1,fstrim_cloned_disks=1
qm set "${PVE_TMP_VMID}" --ciuser "${PVE_USERNAME}"
curl -sfSL "https://github.com/${PVE_USERNAME}.keys" -o "${PVE_USERNAME}.keys"
qm set "${PVE_TMP_VMID}" --sshkeys "${PVE_USERNAME}.keys"
qm template "${PVE_TMP_VMID}"
