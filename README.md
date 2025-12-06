# Arch-Linux-in-Termux-Android-16
Arch Linux in Termux with hardware acceleration, Android 16, no root, no proot-distro.


This was done on Android 16 on a stock Snapdragon 8 Gen 3 device without root access.


First, disable the phantom process monitor. On Android version 16 this is very easy. Go to Settings -> System -> Developer Options -> Disable Child Process Restrictions.

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

In Termux:

pkg update

pkg upgrade

pkg install tar wget xz-utils pulseaudio proot termux-x11-nightly

-----------------------------------------------------------------------------------------

Install recent Termux-x11 .apk on your device also https://github.com/termux/termux-x11

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

nano /etc/pacman.conf # open pacman.conf in nano

Find #DisableSandbox and uncomment it, save and close the file

pacman -Syu

pacman -S ca-certificates ca-certificates-utils

--------------------------------------------------

Back in Termux (not logged into arch):

cd ~/arch-in-termux

mkdir -p arch-binds

Run:

```
cat > arch-binds/shared-tmp.sh << 'EOF'
if [ "$ARCH_X11" = "1" ] && [ -n "$TMPDIR" ]; then
  command+=" -b ${TMPDIR}:/tmp"
fi
EOF
```

cat arch-binds/shared-tmp.sh    # verify file contents

--------------------------------------------------------

Log in to arch again:

cd ~/arch-in-termux

./startarch.sh

Run commands:

pacman -S --needed i3 xterm sudo    # I am using i3wm but you can install a DE like xfce4 later if you want

useradd -m -s /bin/bash proteus117 # <----- Any username here

passwd proteus117

(enter new password)

--------------------------------------------------------

Add your new user to sudo:

visudo

Find the line: root ALL=(ALL:ALL) ALL

Directly under it add a new line for your user:

proteus117 ALL=(ALL:ALL) ALL

Save and exit visudo

---------------------------------------------------------

Still in arch as arch root user:

mkdir /home/proteus117 # user you created

```
cat > /usr/local/bin/starti3-x11 << 'EOF'
#!/bin/bash
export DISPLAY=:0
export PULSE_SERVER=127.0.0.1
exec i3
EOF
```

chmod +x /usr/local/bin/starti3-x11

log out from arch and return to termux

------------------------------------------------------------

Back in termux:

cd

```
cat > xstart-arch-i3 << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
set -e

export XDG_RUNTIME_DIR="$TMPDIR"

# Start Pulse only if not already running
if pgrep -x pulseaudio >/dev/null 2>&1; then
  echo "PulseAudio already running."
else
  pulseaudio --start --exit-idle-time=-1 || echo "PulseAudio start failed (probably already running)."
  pulseaudio --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" || true
fi

# Start Termux:X11 on :0 if not running
if ! pgrep -f "termux-x11" >/dev/null 2>&1; then
  termux-x11 :0 >/dev/null 2>&1 &
fi
sleep 3

cd "$HOME/arch-in-termux"

# Shared /tmp + Arch + i3 as proteus117
ARCH_X11=1 ./startarch.sh "su - proteus117 -c starti3-x11"
EOF
```

Replace the username in the script with the one you created, or edit the config afterwards.

cat ~/xstart-arch-i3 # to verify the file contents

./xstart-arch-i3

Switch to the termux-x11 app, you should see i3 window manager.

Press "enter" : "Yes, Generate the config", also choose your preferred modifier key and then press "enter" again

Press "modifier + enter" to open a new terminal in i3

In i3:

