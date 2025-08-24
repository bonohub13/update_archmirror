#!/usr/bin/sh -eu

mirrorlist_url="https://archlinux.org/mirrorlist"
mirrorlist_settings="country=all&protocol=https&ip_version=6&use_mirror_status=on"

update_mirror() {
    [ `echo "$0" | wc -w` -eq 2 ] && src_mirror="$1" \
        || src_mirror=""

    if [ `echo "$src_mirror" | wc -c` -eq 0 ] || [ -f "$src_mirror" ]; then
        cat "$src_mirror" \
            | sed -e "s/^#Server/Server/" -r -e "s/## +[^_]+//" -e "s/##//" \
            | tee /tmp/mirrorlist
    else
        echo "fetching mirrorlist..."
        curl "$mirrorlist_url/?$mirrorlist_settings" \
            | sed -e "s/^#Server/Server/" -r -e "s/## +[^_]+//" -e "s/##//" \
            | tee /tmp/mirrorlist
    fi
    
    echo "rankmirrors and update mirror? [Y/N]"
    read ask
    
    if [ "$ask" = "Y" -o "$ask" = "y" ]; then
        echo "Backing up current mirrorlist..."
        sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
    
        echo "Adding new raw mirrorlist as mirrorlist.pacnew under /etc/pacman.d"
        sudo cp /tmp/mirrorlist /etc/pacman.d/mirrorlist.pacnew
    
        echo "Ranking mirrors... (This might take a while...)"
        ghostmirror -Po -s light -l /tmp/mirrorlist -L 20 -S state,outofdate,morerecent,extimated,speed -d 12
    
        echo "Adding ranked mirror..."
        sudo cp -v /tmp/mirrorlist /etc/pacman.d/mirrorlist
    
        if [ $? -eq 0 ]; then
            echo "Successfully updated mirrorlist to /etc/pacman.d/mirrorlist"
        return 0
        else
            echo "Failed to updated mirrorlist"
            echo "update-archmirror terminated..."
            return 1
        fi
    else
        echo "update-archmirror terminated..."
        return 1
    fi
}

echo "Searching if required packages are installed"
if [ `pacman -Qtn | grep pacman-contrib | wc -l` -gt 0 ]; then
    [ `echo "$0" | wc -w` -eq 2 ] && update_mirror "$1" \
        || update_mirror
else
    echo "Required package (pacman-contrib) not found."
    echo "Please install required package to use this command."
    return 1
fi
