#!/usr/bin/env bash
# Lanza la VM de Windows 10 en VirtualBox

VM_NAME="win10"

# Verificar que el disco con los VHDs esté montado
if ! mountpoint -q /mnt/vbox; then
    echo "Montando disco de VHDs..."
    sudo mount /mnt/vbox || { echo "Error al montar /mnt/vbox"; exit 1; }
fi

# Verificar que el VHD existe
if [[ ! -f /mnt/vbox/DESKTOP-4ESNH4K-0.VHD ]]; then
    echo "No se encontró el VHD en /mnt/vbox/"
    exit 1
fi

# Lanzar la VM
if VBoxManage showvminfo "$VM_NAME" --machinereadable | grep -q 'VMState="running"'; then
    echo "La VM ya está corriendo"
else
    echo "Iniciando $VM_NAME..."
    VBoxManage startvm "$VM_NAME" --type gui
fi
