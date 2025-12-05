#!/data/data/com.termux/files/usr/bin/bash
set -e

time1="$( date +"%r" )"

install1() {
    directory=arch-fs
    ROOTFS_TARBALL=arch-rootfs.tar.gz

    if [ -d "$directory" ] && [ -n "$(ls -A "$directory" 2>/dev/null)" ]; then
        printf "\n[%s] Arch rootfs already exists at ./%s, skipping download & extract\n" "$time1" "$directory"
    else
        # Basic deps in Termux
        for pkg in proot wget tar; do
            if ! command -v "$pkg" >/dev/null 2>&1; then
                echo "Please install '$pkg' in Termux first:  pkg install $pkg"
                exit 1
            fi
        done

        ARCH=$(dpkg --print-architecture)
        case "$ARCH" in
            aarch64)
                # Arch Linux ARM generic AArch64 rootfs 
                ROOTFS_URL="http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz"
                ;;
            arm)
                ROOTFS_URL="http://os.archlinuxarm.org/os/ArchLinuxARM-armv7-latest.tar.gz"
                ;;
            x86_64|amd64)
                # For x86_64 Termux devices, you could instead use the Arch bootstrap tarball
                # from an official Arch mirror, e.g. archlinux-bootstrap-x86_64.tar.zst 
                echo "x86_64 bootstrap not wired here yet; this script is tuned for ARM (aarch64/arm)."
                exit 1
                ;;
            *)
                echo "Unsupported architecture: $ARCH"
                exit 1
                ;;
        esac

        echo
        echo "[${time1}] Downloading Arch rootfs (${ROOTFS_URL}) ..."
        wget -q -O "$ROOTFS_TARBALL" "$ROOTFS_URL"
        echo "[${time1}] Download complete!"

        echo "[${time1}] Extracting Arch rootfs into ./$directory ..."
        mkdir -p "$directory"
        cur="$(pwd)"
        cd "$directory"

        proot --link2symlink tar -xpf "$cur/$ROOTFS_TARBALL" \
          --exclude='./etc/ca-certificates/extracted/*' \
          --exclude='./etc/ca-certificates/extracted/**' \
          --exclude='./etc/ssl/certs/*' \
          --exclude='./etc/ssl/certs/**' \
          || :


        cd "$cur"
        echo "[${time1}] Extraction done."

        mkdir -p "$directory/etc"
        printf "nameserver 8.8.8.8\nnameserver 1.1.1.1\n" > "$directory/etc/resolv.conf" || true
        
        mkdir -p "$directory/tmp"

    fi

    # Binds dir
    mkdir -p arch-binds

    # Create start script
    bin=startarch.sh
    cat > "$bin" << EOM
#!/bin/bash
cd \$(dirname "\$0")
unset LD_PRELOAD

command="proot"
command+=" --link2symlink"
command+=" -0"
command+=" -r $directory"

# Optional extra bind scripts (e.g. /tmp sharing for X11)
if [ -d arch-binds ] && [ -n "\$(ls -A arch-binds 2>/dev/null)" ]; then
    for f in arch-binds/*; do
        . "\$f"
    done
fi

command+=" -b /dev"
command+=" -b /proc"
command+=" -b /sys"
command+=" -b $directory/tmp:/dev/shm"
command+=" -b /data/data/com.termux"
command+=" -b /:/host-rootfs"
command+=" -b /sdcard"
command+=" -b /storage"
command+=" -b /mnt"
command+=" -w /root"

command+=" /usr/bin/env -i"
command+=" HOME=/root"
command+=" PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
command+=" TERM=\$TERM"
command+=" LANG=C.UTF-8"
command+=" /bin/bash --login"

com="\$@"
if [ -z "\$1" ]; then
    exec \$command
else
    \$command -c "\$com"
fi
EOM

    termux-fix-shebang "$bin"
    chmod +x "$bin"

    # Clean up tarball
    rm -f "$ROOTFS_TARBALL"

    echo
    echo "[${time1}] Arch installation completed."
    echo "You can now start Arch with:  ./startarch.sh"
}

if [ "$1" = "-y" ]; then
    install1
elif [ -z "$1" ]; then
    printf "Do you want to install Arch-in-Termux now? [Y/n] "
    read -r ans
    if [ "$ans" = "y" ] || [ "$ans" = "Y" ] || [ -z "$ans" ]; then
        install1
    else
        echo "Installation aborted."
        exit 0
    fi
else
    echo "Usage: $0 [-y]"
    exit 1
fi
