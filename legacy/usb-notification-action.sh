#!/usr/bin/env bash

DEVICE_NAME="${1}"
ICON="${2}"
MOUNT_POINT="${3}"

# --- CORRECTION DES ESPACES ---
MOUNT_POINT=$(printf '%b' "${MOUNT_POINT}")

LOG_FILE="/tmp/usb-watcher-debug.log"

log() {
    echo "$(date) - $*" >> "${LOG_FILE}"
}

log "Action script appelée avec : DEVICE=${DEVICE_NAME}, ICON=${ICON}, MOUNT=${MOUNT_POINT}"

# On exporte pour être sûr que notify-send et gio fonctionnent
export DISPLAY=:0
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus

if [[ -n "${MOUNT_POINT}" ]]; then
    # --- CAS STOCKAGE (Avec bouton) ---
    action=$(notify-send "Périphérique USB branché" "<b>${DEVICE_NAME}</b>" \
        --icon="${ICON}" \
        -h string:sound-file:/usr/share/sounds/zorin/stereo/device-added.oga \
        -u critical \
        -a USB \
        -A "Ouvrir dans Nautilus")

    log "notify-send a retourné : '${action}'"

    if [[ "${action}" == "0" ]]; then
        log "Lancement de Nautilus sur ${MOUNT_POINT}"
        gio open "${MOUNT_POINT}" &>> "${LOG_FILE}" &
    else
        log "Aucune action sélectionnée."
    fi
else
    # --- CAS HID / SOURIS (Sans bouton) ---
    notify-send "Matériel connecté" "${DEVICE_NAME}" \
        --icon="${ICON}" \
        -h string:sound-file:/usr/share/sounds/zorin/stereo/device-added.oga \
        -u normal \
        -a USB
    
    log "Notification simple envoyée pour HID."
fi
