# How to install VM hyprland KODVMV dotfiles?

Preparing to install hyprland into qemu KVM it's necessary to do:
1.) Download QEMU image from the official repository
    https://gitlab.archlinux.org/archlinux/arch-boxes/-/packages/1760
2.) Run that disk with the next command:
    qemu-system-x86_64 -enable-kvm -m 8000 \
        -cpu host -smp 4 \
        -drive file=Arch-Linux-x86_64-basic-20250301.315930.qcow2,format=qcow2 \
        -netdev user,id=net0 -device virtio-net,netdev=net0 \
        -boot d



Install hyprland enviroment:

1.) Load credentials (arch/arch) 
2.) sudo pacman -Syu
3.) sudo pacman -S hyprland

