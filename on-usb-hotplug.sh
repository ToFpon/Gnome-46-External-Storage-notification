#!/usr/bin/env bash
CMD=$1
BUSNUM="${2:-${BUSNUM:-inconnu}}"
PORTNUM="${3:-${DEVNUM:-inconnu}}"

print_date() {
    date +%Y-%m-%d_%H%M%S
}

# Log dans le fichier
echo "$(print_date) USB change detected: $CMD bus=$BUSNUM port=$PORTNUM" >> /tmp/on-usb-hotplug.txt

# Notification uniquement lors du branchement
if [ "$CMD" = "add" ]; then
    # Récupère les infos du périphérique
    VENDOR=$(cat /sys/bus/usb/devices/$BUSNUM-*/manufacturer 2>/dev/null | head -n1)
    PRODUCT=$(cat /sys/bus/usb/devices/$BUSNUM-*/product 2>/dev/null | head -n1)
    
    # Construit le nom du périphérique
    if [ -n "$VENDOR" ] && [ -n "$PRODUCT" ]; then
        DEVICE_NAME="$VENDOR $PRODUCT"
    elif [ -n "$PRODUCT" ]; then
        DEVICE_NAME="$PRODUCT"
    else
        DEVICE_NAME="Périphérique USB"
    fi
    
    # Détecte le type de périphérique et choisit l'icône
    ICON="drive-removable-media"
    
    if echo "$PRODUCT $VENDOR" | grep -Eqi "phone|android|iphone|samsung|xiaomi|huawei|pixel|google|oneplus|oppo|realme|motorola"; then
        ICON="phone"
    elif echo "$PRODUCT $VENDOR" | grep -Eqi "ssd|nvme|solid.?state"; then
        ICON="drive-harddisk-solidstate"
    elif echo "$PRODUCT $VENDOR" | grep -Eqi "card.?reader|sd|mmc"; then
        ICON="media-flash-sd"
    elif echo "$PRODUCT $VENDOR" | grep -Eqi "storage|flash|usb|disk|mass"; then
        ICON="drive-removable-media-usb-pendrive"
    fi
    
    # Récupère l'utilisateur actuellement connecté
    for user in $(who | awk '{print $1}' | sort -u); do
        user_id=$(id -u "$user")
        
        # Écrit les infos dans un fichier trigger pour le service utilisateur
        rm -f "/tmp/usb-hotplug-$user_id.trigger"
        echo "$DEVICE_NAME|$ICON|" > "/tmp/usb-hotplug-$user_id.trigger"
        
        # Donne les permissions à l'utilisateur
        chown "$user:$user" "/tmp/usb-hotplug-$user_id.trigger"
        chmod 666 "/tmp/usb-hotplug-$user_id.trigger"
    done
fi
