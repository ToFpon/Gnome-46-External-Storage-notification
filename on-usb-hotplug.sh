#!/usr/bin/env bash
CMD=$1

# On récupère les infos via les variables que udev nous envoie
# Pour les cartes SD, ID_MODEL_FROM_DATABASE est souvent le plus précis
DEVICE_NAME="${ID_MODEL_FROM_DATABASE:-${ID_MODEL:-Périphérique de stockage}}"

# Détection de l'icône
ICON="drive-removable-media"
if echo "$DEVICE_NAME" | grep -Eqi "sd|mmc|card|reader"; then
    ICON="media-flash-sd"
fi

# Notif
if [ "$CMD" = "add" ]; then
    for user in $(who | awk '{print $1}' | sort -u); do
        user_id=$(id -u "$user")
        echo "$DEVICE_NAME|$ICON|" > "/tmp/usb-hotplug-$user_id.trigger"
        chown "$user:$user" "/tmp/usb-hotplug-$user_id.trigger"
        chmod 666 "/tmp/usb-hotplug-$user_id.trigger"
    done
fi
