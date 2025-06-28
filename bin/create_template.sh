#!/bin/bash
# from https://github.com/MikeTangoSierra/ProxmoxAutomation/blob/master/create_template.sh

// Download Cloud Image
wget <cloudimageurl>

// Install libguestfs package (only needs to be done once, wrap in if)
sudo apt install libguestfs-tools -y

// Install QEMU guest agent
sudo virt-customize -a <imagename.img> --install qemu-guest-agent

// Create VM to be used as a base for future images
qm create <VM_ID_NUMBER> \\
  --name <VM_NAME> --numa 0 --ostype <OS_TYPE> \\
  --cpu cputype=host --cores <CPU_CORES> --sockets <CPU_SOCKETS> \\
  --memory <MEMORY_IN_MB>  \\
  --net0 virtio,bridge=vmbr0

// Import the cloud image to storage pool.
qm importdisk <VM_ID_NUMBER> <imagename.img> <storagepool_name>

// Attach the disk to the VM as a SCSI drive.
qm set <VM_ID_NUMBER> --scsihw virtio-scsi-pci --scsi0 <storagepool_name>:vm-<VM_ID_NUMBER>-disk-0

// Create cloudinit CDROM drive
qm set <VM_ID_NUMBER> --ide2 <storagepool_name>:cloudinit

// Make the VM disk bootable.
qm set <VM_ID_NUMBER> --boot c --bootdisk scsi0

// Assign a serial console to the VM
qm set <VM_ID_NUMBER> --serial0 socket --vga serial0

// Enable the guest agent.
qm set <VM_ID_NUMBER> --agent enabled=1

// Convert the VM to a template
qm template <VM_ID_NUMBER>
