#!/usr/bin/env bash
# ~/.local/bin/usb-notification-watcher.sh

USER_ID=$(id -u)
TRIGGER_DIR="/tmp"
TRIGGER_PATTERN="usb-hotplug-$USER_ID.trigger"
LOG_FILE="/tmp/usb-watcher.log"

# Fonction de log pour savoir ce qui se passe
log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log_msg "Démarrage du watcher pour l'utilisateur $USER_ID"

inotifywait -m -e create --format '%f' "$TRIGGER_DIR" | while read -r filename; do
    if [[ "$filename" == "$TRIGGER_PATTERN" ]]; then
        TRIGGER_FILE="$TRIGGER_DIR/$filename"
        log_msg "Trigger détecté : $filename"
        
        sleep 0.5   # Un peu plus de temps pour laisser le système monter le périphérique

        [[ -f "$TRIGGER_FILE" ]] || { log_msg "Erreur : Trigger disparu"; continue; }

        # Lecture du trigger
        IFS='|' read -r DEVICE_NAME ICON _ < "$TRIGGER_FILE"
        rm -f "$TRIGGER_FILE"
        log_msg "Périphérique : $DEVICE_NAME"

        # ---------- Recherche du point de montage ----------
        MAX_WAIT=6      # On augmente un peu pour les smartphones
        STEP=0.5
        elapsed=0
        MOUNT_POINT=""

        log_msg "Début de la recherche du point de montage..."

        while (( $(bc <<< "$elapsed < $MAX_WAIT") )); do
            # 1. Test classique (Clé USB / Disque)
            MOUNT_POINT=$(findmnt -rn -o TARGET | grep "^/media/$USER/" | head -n 1)
            
            # 2. Test MTP (Smartphone) si la clé USB n'est pas trouvée
            if [[ -z "$MOUNT_POINT" ]]; then
                MTP_PATH=$(ls "/run/user/$USER_ID/gvfs/" 2>/dev/null | grep -m1 "mtp:host=")
                if [[ -n "$MTP_PATH" ]]; then
                    MOUNT_POINT="/run/user/$USER_ID/gvfs/$MTP_PATH"
                    log_msg "MTP trouvé dans GVFS : $MTP_PATH"
                fi
            fi

            if [[ -n "$MOUNT_POINT" ]]; then
                log_msg "Succès ! Montage trouvé : $MOUNT_POINT"
                break
            fi
            
            sleep "$STEP"
            elapsed=$(bc <<< "$elapsed+$STEP")
        done

        # Fallback si rien trouvé
        if [[ -z "$MOUNT_POINT" ]]; then
            log_msg "ECHEC : Aucun montage trouvé après ${MAX_WAIT}s. Fallback sur HOME."
            MOUNT_POINT="$HOME"
        fi

        # ---------- Appel du script d’action ----------
        log_msg "Appel de l'action avec : $MOUNT_POINT"
        "$HOME/.local/bin/usb-notification-action.sh" \
            "$DEVICE_NAME" "$ICON" "$MOUNT_POINT" & >> "$LOG_FILE" 2>&1
        
        log_msg "------------------------------------------"
    fi
done
