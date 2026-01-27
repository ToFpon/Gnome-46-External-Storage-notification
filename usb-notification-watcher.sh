#!/usr/bin/env bash
# ~/.local/bin/usb-notification-watcher.sh

USER_ID=$(id -u)
TRIGGER_DIR="/tmp"
TRIGGER_PATTERN="usb-hotplug-$USER_ID.trigger"
LOG_FILE="/tmp/usb-watcher.log"

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Fonction magique pour transformer %20 en espace
decode_url() {
    printf '%b\n' "${1//%/\\x}"
}

log_msg "Démarrage du watcher pour l'utilisateur $USER_ID"

inotifywait -m -e create --format '%f' "$TRIGGER_DIR" | while read -r filename; do
    if [[ "$filename" == "$TRIGGER_PATTERN" ]]; then
        TRIGGER_FILE="$TRIGGER_DIR/$filename"
        log_msg "Trigger détecté : $filename"
        
        sleep 0.8

        [[ -f "$TRIGGER_FILE" ]] || { log_msg "Erreur : Trigger disparu"; continue; }

        # Lecture initiale
        IFS='|' read -r DEVICE_NAME ICON _ < "$TRIGGER_FILE"
        rm -f "$TRIGGER_FILE"

        # ---------- Recherche du point de montage ----------
        MAX_WAIT=7
        STEP=0.5
        elapsed=0
        MOUNT_POINT=""

        while (( $(bc <<< "$elapsed < $MAX_WAIT") )); do
            MOUNT_POINT=$(findmnt -rn -o TARGET | grep "^/media/$USER/" | head -n 1)
            
            if [[ -z "$MOUNT_POINT" ]]; then
                MTP_PATH=$(ls "/run/user/$USER_ID/gvfs/" 2>/dev/null | grep -m1 "mtp:host=")
                if [[ -n "$MTP_PATH" ]]; then
                    MOUNT_POINT="/run/user/$USER_ID/gvfs/$MTP_PATH"
                fi
            fi

            [[ -n "$MOUNT_POINT" ]] && break
            sleep "$STEP"
            elapsed=$(bc <<< "$elapsed+$STEP")
        done

        # ---------- LOGIQUE DE NETTOYAGE DU LABEL ----------
        FINAL_LABEL="$DEVICE_NAME"

        if [[ -n "$MOUNT_POINT" && "$MOUNT_POINT" != "$HOME" ]]; then
            FOLDER_NAME=$(basename "$MOUNT_POINT")
            
            if [[ "$MOUNT_POINT" == *"gvfs"* ]]; then
                # --- LOGIQUE SMARTPHONE (Ton code d'orfèvre) ---
                # 1. On enlève le préfixe gvfs
                # 2. On remplace les underscores par des espaces
                # 3. On coupe TOUT ce qui ressemble à un ID de série (lettres+chiffres longs à la fin)
                FINAL_LABEL=$(echo "$FOLDER_NAME" | sed 's/mtp:host=//; s/_/ /g' | sed -E 's/ [A-Z0-9]{10,25}//g')
                log_msg "Nettoyage Smartphone : $FOLDER_NAME -> $FINAL_LABEL"
            else
                # --- LOGIQUE CLÉ USB / SD ---
                # On décode les %20 et on remplace les underscores
                TEMP_LABEL=$(decode_url "$FOLDER_NAME")
                FINAL_LABEL=$(echo "$TEMP_LABEL" | sed 's/_/ /g' | xargs)
                log_msg "Nettoyage Disque : $FOLDER_NAME -> $FINAL_LABEL"
            fi
        fi

        # Nettoyage final des espaces en trop
        FINAL_LABEL=$(echo "$FINAL_LABEL" | xargs)

        # ---------- Appel de l'action ----------
        "$HOME/.local/bin/usb-notification-action.sh" \
            "$FINAL_LABEL" "$ICON" "$MOUNT_POINT" & >> "$LOG_FILE" 2>&1
        
        log_msg "------------------------------------------"
    fi
done
