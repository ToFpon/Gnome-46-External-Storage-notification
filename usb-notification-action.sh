#!/usr/bin/env bash

DEVICE_NAME="${1}"
ICON="${2}"
MOUNT_POINT="${3}"

# --- LA CORRECTION POUR LES ESPACES ---
# On transforme les \x20 en vrais espaces
MOUNT_POINT=$(printf '%b' "${MOUNT_POINT}")
# --------------------------------------

LOG_FILE="/tmp/usb-watcher-debug.log"

log() {
    echo "$(date) - $*" >> "${LOG_FILE}"
}

log "Action script appelée avec : DEVICE=${DEVICE_NAME}, ICON=${ICON}, MOUNT=${MOUNT_POINT}"
log "Variables d'env : DISPLAY=${DISPLAY}, DBUS_SESSION_BUS_ADDRESS=${DBUS_SESSION_BUS_ADDRESS}"

# Affiche la notification avec une action « Ouvrir »
action=$(notify-send "USB branché" "${DEVICE_NAME}" \
    --icon="${ICON}" \
    -h string:sound-file:/usr/share/sounds/zorin/stereo/device-added.oga \
    -u critical \
    -a USB \
    -A "Ouvrir dans Nautilus")

log "notify-send a retourné : '${action}'"

# Si l'utilisateur a cliqué sur l'action (index = 0), on ouvre le gestionnaire
if [[ "${action}" == "0" ]]; then
    log "Lancement de Nautilus…"
    TARGET="${MOUNT_POINT}"
    # Si le point de montage est vide ou inexistant, on revient au répertoire HOME
    [[ -z "${TARGET}" || ! -d "${TARGET}" ]] && TARGET="${HOME}"
    
    # Utiliser gio open ou xdg-open
    gio open "${TARGET}" &>> "${LOG_FILE}" &
    log "gio open lancé (PID: $!)"
else
    log "Aucune action sélectionnée – rien à faire."
fi
