#!/bin/bash
# from https://github.com/MikeTangoSierra/ProxmoxAutomation/blob/master/create_vm.sh

// Create VM
qm clone <TEMPLATE_VM_ID_NUMBER> <NEW_VM_ID_NUMBER> \\
  --name <VM_NAME> \\
  --full \\
  --storage <LVM_STORAGE_NAME>

// Assign IP to VM
qm set <NEW_VM_ID_NUMBER> --sshkey <path/to/key.pub>

// Assign IP to VM
qm set <NEW_VM_ID_NUMBER> --ipconfig0 ip=<PRIVATE_IP_TO_ASSIGN>/24,gw=<GATEWAY_IP>

// Start the VM
qm start <NEW_VM_ID_NUMBER>
