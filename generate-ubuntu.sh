#!/usr/bin/env bash

set -eux

DISTRIB_ID="ubuntu"
DISTRIB_CODENAME="focal" # Ubuntu 20.04 LTS

PVE_TMP_VMID="9011"
PVE_VOLUME="cephrbd01"
PVE_NET0_VLAN="221"
PVE_USERNAME="naa0yama"

mkdir -p "${DISTRIB_ID}/${DISTRIB_CODENAME}"
cd "${DISTRIB_ID}/${DISTRIB_CODENAME}"

if ! [ -f "${DISTRIB_CODENAME}-server-cloudimg-amd64_edited.img" ]; then
    wget -c "https://cloud-images.ubuntu.com/${DISTRIB_CODENAME}/current/${DISTRIB_CODENAME}-server-cloudimg-amd64.img"
    wget -c "https://cloud-images.ubuntu.com/${DISTRIB_CODENAME}/current/SHA256SUMS"
    grep -e "${DISTRIB_CODENAME}-server-cloudimg-amd64.img" "SHA256SUMS" | sha256sum -c -
    mv "${DISTRIB_CODENAME}-server-cloudimg-amd64.img" "${DISTRIB_CODENAME}-server-cloudimg-amd64_edited.img"
fi

virt-copy-in -a "${DISTRIB_CODENAME}-server-cloudimg-amd64_edited.img" ../11_template.cfg /etc/cloud/cloud.cfg.d/
virt-ls -a "${DISTRIB_CODENAME}-server-cloudimg-amd64_edited.img" /etc/cloud/cloud.cfg.d/

qm create "${PVE_TMP_VMID}" --name "Ubuntu-20.04" --cores 2 --memory 2048 --net0 virtio,bridge=vmbr0,tag="${PVE_NET0_VLAN}"
qm importdisk "${PVE_TMP_VMID}" "${DISTRIB_CODENAME}-server-cloudimg-amd64_edited.img" "${PVE_VOLUME}"
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
