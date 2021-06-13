#!/usr/bin/sh -eu

mirrorlist_url="https://archlinux.org/mirrorlist"
mirrorlist_settings="country=all&protocol=https&ip_version=4&ip_version=6&use_mirror_status=on"

update_mirror() {
    echo "fetching mirrorlist..."
    curl "$mirrorlist_url/?$mirrorlist_settings" \
        | sed -e "s/^#Server/Server/" -r -e "s/## +[^_]+//" -e "s/##//" \
        | tee /tmp/mirrorlist
    
    echo "rankmirrors and update mirror? [Y/N]"
    read ask
    
    if [ "$ask" = "Y" -o "$ask" = "y" ]; then
        echo "Backing up current mirrorlist..."
        sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
    
        echo "Adding new raw mirrorlist as mirrorlist.pacnew under /etc/pacman.d"
        sudo cp /tmp/mirrorlist /etc/pacman.d/mirrorlist.pacnew
    
        echo "Ranking mirrors... (This might take a while...)"
        rankmirrors -n 20 /tmp/mirrorlist | tee /tmp/mirrorlist.new
    
        echo "Adding ranked mirror..."
        sudo cp /tmp/mirrorlist.new /etc/pacman.d/mirrorlist
    
        if [ "$?" -eq 0 ]; then
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
    update_mirror
else
    echo "Required package (pacman-contrib) not found."
    echo "Please install required package to use this command."
    return 1
fi
