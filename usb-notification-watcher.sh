#!/usr/bin/env bash
# ~/.local/bin/usb-notification-watcher.sh

USER_ID=$(id -u)
TRIGGER_DIR="/tmp"
TRIGGER_PATTERN="usb-hotplug-$USER_ID.trigger"
LOG_FILE="/tmp/usb-watcher.log"

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

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

        IFS='|' read -r DEVICE_NAME ICON _ < "$TRIGGER_FILE"
        rm -f "$TRIGGER_FILE"

        # ---------- Recherche du point de montage ----------
        MAX_WAIT=4 
        STEP=0.5
        elapsed=0
        MOUNT_POINT=""

        while (( $(bc <<< "$elapsed < $MAX_WAIT") )); do
            MOUNT_POINT=$(findmnt -rn -o TARGET | grep "^/media/$USER/" | head -n 1)
            if [[ -z "$MOUNT_POINT" ]]; then
                MTP_PATH=$(ls "/run/user/$USER_ID/gvfs/" 2>/dev/null | grep -m1 "mtp:host=")
                [[ -n "$MTP_PATH" ]] && MOUNT_POINT="/run/user/$USER_ID/gvfs/$MTP_PATH"
            fi
            [[ -n "$MOUNT_POINT" ]] && break
            sleep "$STEP"
            elapsed=$(bc <<< "$elapsed+$STEP")
        done

        # ---------- Détermination du Label et du Mode ----------
        FINAL_LABEL="$DEVICE_NAME"
        
        if [[ -n "$MOUNT_POINT" ]]; then
            if [[ "$MOUNT_POINT" == *"gvfs"* ]]; then
                # --- STRATÉGIE ADB (NOM DE LUXE) ---
                log_msg "Tentative de récupération du nom via ADB..."
                # On attend 1s max pour ne pas bloquer si le tel n'est pas en débug
                ADB_NAME=$(timeout 1.2s adb shell settings get global device_name 2>/dev/null | tr -d '\r')
                
                if [[ -z "$ADB_NAME" || "$ADB_NAME" == "null" ]]; then
                    # Fallback sur la méthode classique si ADB échoue
                    FOLDER_NAME=$(basename "$MOUNT_POINT")
                    FINAL_LABEL=$(echo "$FOLDER_NAME" | sed 's/mtp:host=//; s/_/ /g' | sed -E 's/ [A-Z0-9]{10,25}//g')
                    log_msg "ADB a échoué, utilisation du label MTP classique."
                else
                    FINAL_LABEL="$ADB_NAME"
                    log_msg "Nom récupéré via ADB : $FINAL_LABEL"
                fi
            else
                # Stockage USB Classique
                FOLDER_NAME=$(basename "$MOUNT_POINT")
                TEMP_LABEL=$(decode_url "$FOLDER_NAME")
                FINAL_LABEL=$(echo "$TEMP_LABEL" | sed 's/_/ /g' | xargs)
            fi
        fi

        FINAL_LABEL=$(echo "$FINAL_LABEL" | xargs)

        # ---------- Appel de l'action ----------
        "$HOME/.local/bin/usb-notification-action.sh" \
            "$FINAL_LABEL" "$ICON" "$MOUNT_POINT" & >> "$LOG_FILE" 2>&1
        
        log_msg "------------------------------------------"
    fi
done
