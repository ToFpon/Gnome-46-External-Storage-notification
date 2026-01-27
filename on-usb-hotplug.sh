#!/usr/bin/env bash
CMD=$1
BUSNUM="${2:-${BUSNUM:-}}"

# 1. Éviter les doublons
if [ "$SUBSYSTEM" == "block" ] && [ "$ID_BUS" == "usb" ]; then
    exit 0
fi

# --- RÉCUPÉRATION DU LABEL (Comme tu l'aimes) ---

# On essaie d'abord de voir si la partition a un nom (ex: "DEDEE", "BACKUP")
if [ -n "$ID_FS_LABEL" ]; then
    DEVICE_NAME="$ID_FS_LABEL"
else
    # Sinon on prend le nom du constructeur (Méthode Hier)
    VENDOR=$(cat /sys/bus/usb/devices/$BUSNUM-*/manufacturer 2>/dev/null | head -n1)
    PRODUCT=$(cat /sys/bus/usb/devices/$BUSNUM-*/product 2>/dev/null | head -n1)
    
    if [ -n "$VENDOR" ] && [ -n "$PRODUCT" ]; then
        DEVICE_NAME="$VENDOR $PRODUCT"
    else
        # Secours pour la SD
        DEVICE_NAME="${ID_MODEL_FROM_DATABASE:-${ID_MODEL:-Périphérique}}"
    fi
fi

# Nettoyage
DEVICE_NAME=$(echo "$DEVICE_NAME" | xargs)

# --- LOGIQUE DES ICÔNES ---
ICON="drive-removable-media"
CLEAN_NAME=$(echo "$DEVICE_NAME" | tr '[:upper:]' '[:lower:]')

# Détection précise de l'icône
if echo "$CLEAN_NAME" | grep -Eqi "phone|android|pixel|google|samsung"; then
    ICON="phone"
# On ajoute 'external', 'drive' et 'hdd' pour capturer les disques durs
elif echo "$CLEAN_NAME" | grep -Eqi "ssd|nvme|solid.?state|external|drive|hdd"; then
    ICON="drive-harddisk-solidstate"
elif [ "$SUBSYSTEM" == "mmc" ] || echo "$CLEAN_NAME" | grep -Eqi "sd|mmc|card"; then
    ICON="media-flash"
elif echo "$CLEAN_NAME" | grep -Eqi "storage|flash|usb|disk|mass"; then
    ICON="drive-removable-media-usb-pendrive"
fi

# --- ENVOI ---
if [ "$CMD" = "add" ]; then
    for user in $(who | awk '{print $1}' | sort -u); do
        user_id=$(id -u "$user")
        echo "$DEVICE_NAME|$ICON|" > "/tmp/usb-hotplug-$user_id.trigger"
        chown "$user:$user" "/tmp/usb-hotplug-$user_id.trigger"
        chmod 666 "/tmp/usb-hotplug-$user_id.trigger"
    done
fi
