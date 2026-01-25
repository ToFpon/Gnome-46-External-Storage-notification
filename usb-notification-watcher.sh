#!/usr/bin/env bash
# ~/.local/bin/usb-notification-watcher.sh

USER_ID=$(id -u)
TRIGGER_DIR="/tmp"
TRIGGER_PATTERN="usb-hotplug-$USER_ID.trigger"

inotifywait -m -e create --format '%f' "$TRIGGER_DIR" | while read -r filename; do
    if [[ "$filename" == "$TRIGGER_PATTERN" ]]; then
        TRIGGER_FILE="$TRIGGER_DIR/$filename"
        sleep 0.2   # laisser le créateur finir d’écrire

        [[ -f "$TRIGGER_FILE" ]] || continue

        # Lecture du trigger
        IFS='|' read -r DEVICE_NAME ICON _ < "$TRIGGER_FILE"
        rm -f "$TRIGGER_FILE"

        # ---------- Recherche du point de montage ----------
        MAX_WAIT=4      # seconds
        STEP=0.4        # seconds
        elapsed=0
        MOUNT_POINT=""

        while (( $(bc <<< "$elapsed < $MAX_WAIT") )); do
           MOUNT_POINT=$(findmnt -rn -o TARGET | grep "^/media/$USER/" | head -n 1)
            [[ -n "$MOUNT_POINT" ]] && break
            sleep "$STEP"
            elapsed=$(bc <<< "$elapsed+$STEP")
        done

        # Fallback si rien trouvé
        [[ -z "$MOUNT_POINT" ]] && MOUNT_POINT="$HOME"

        # ---------- Appel du script d’action ----------
        "$HOME/.local/bin/usb-notification-action.sh" \
            "$DEVICE_NAME" "$ICON" "$MOUNT_POINT" &
    fi
done
