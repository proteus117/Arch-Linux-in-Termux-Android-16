# Arch-Linux-in-Termux-Android-16
Arch Linux in Termux with hardware acceleration, Android 16, no root, no proot-distro.


This was done on Android 16 on a stock Snapdragon 8 Gen 3 device without root access.


First, disable the phantom process monitor. On Android version 16 this is very easy. Go to Settings -> System -> Developer Options -> Disable Child Process Restrictions.

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

In Termux:

pkg update

pkg upgrade

-----------------------------------------------------------------------------------------

echo 'allow-external-apps = true' >> ~/.termux/termux.properties  # If you havent already

termux-setup-storage  # If you havent already

---------------------------------------------

mkdir -p ~/arch-in-termux
cd ~/arch-in-termux

curl -o arch.sh "https://raw.githubusercontent.com/proteus117/Arch-Linux-in-Termux-Android-16/refs/heads/main/arch.sh"

Run './arch.sh -y' in this directory (~/arch-in-termux). A generic AArch64 rootfs tarball is installed.

--------------------------------------------------------------------------------------------------------

Run './startarch.sh' to enter the new system

From the root shell you just entered: 

pacman-key --init
pacman-key --populate archlinuxarm
pacman -Syu

