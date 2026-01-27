#!/usr/bin/env bash
CMD=$1
BUSNUM="${2:-${BUSNUM:-}}"

# --- 1. FILTRE ANTI-HID (SOURIS/CLAVIER) ---
# On utilise ton filtre qui marche super bien
IS_STORAGE=$(udevadm info --query=property --name=$DEVNAME 2>/dev/null | grep -E "ID_USB_INTERFACES|ID_SERIAL" | grep -E ":08|phone|android|pixel")

if [ "$CMD" = "add" ] && [ -z "$IS_STORAGE" ] && [ "$SUBSYSTEM" == "usb" ]; then
    exit 0
fi

# --- 2. ÉVITER LES DOUBLONS ---
# Si c'est un périphérique USB, on laisse la règle USB gérer. 
# Si c'est la règle BLOCK qui tourne pour de l'USB, on arrête.
if [ "$SUBSYSTEM" == "block" ] && [ "$ID_BUS" == "usb" ]; then
    exit 0
fi

# --- 3. RÉCUPÉRATION DU NOM ET ICÔNE ---
# On cherche le nom le plus précis possible
DEVICE_NAME="${ID_MODEL_FROM_DATABASE:-${ID_MODEL:-${ID_NAME:-Périphérique}}}"

# On définit l'icône par défaut
ICON="drive-removable-media"

# Détection précise de l'icône
# On checke le nom mais aussi le sous-système (MMC = souvent Carte SD)
if echo "$DEVICE_NAME" | grep -Eqi "phone|android|pixel|google|samsung"; then
    ICON="phone"
elif echo "$DEVICE_NAME" | grep -Eqi "ssd|nvme|solid.?state"; then
    ICON="drive-harddisk-solidstate"
elif [ "$SUBSYSTEM" == "mmc" ] || echo "$DEVPATH $DEVICE_NAME" | grep -Eqi "sd|mmc|card"; then
    ICON="media-flash"
elif echo "$DEVICE_NAME" | grep -Eqi "storage|flash|usb|disk|mass"; then
    ICON="drive-removable-media-usb-pendrive"
fi

# --- 4. ENVOI DE LA NOTIFICATION ---
if [ "$CMD" = "add" ]; then
    # Log pour vérifier ce qui se passe (optionnel)
    echo "$(date) - Notif pour: $DEVICE_NAME (Icon: $ICON)" >> /tmp/on-usb-hotplug.txt

    for user in $(who | awk '{print $1}' | sort -u); do
        user_id=$(id -u "$user")
        echo "$DEVICE_NAME|$ICON|" > "/tmp/usb-hotplug-$user_id.trigger"
        chown "$user:$user" "/tmp/usb-hotplug-$user_id.trigger"
        chmod 666 "/tmp/usb-hotplug-$user_id.trigger"
    done
fi
