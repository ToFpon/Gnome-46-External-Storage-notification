#!/bin/sh
# Notification au branchement d'un stockage externe pour GNOME 46.
#   ./install.sh              installe (pour l'utilisateur courant, sans sudo)
#   ./install.sh --uninstall  désinstalle
# L'ancienne version (règle udev + scripts, dossier legacy/) est retirée si elle est trouvée.
set -e
cd "$(dirname "$0")"
BIN="$HOME/.local/bin"
UNITS="$HOME/.config/systemd/user"

remove_legacy() {
    if [ -f "$UNITS/usb-notification-watcher.service" ]; then
        echo "> Ancienne version trouvée : arrêt de usb-notification-watcher"
        systemctl --user disable --now usb-notification-watcher.service 2>/dev/null || true
        rm -f "$UNITS/usb-notification-watcher.service" "$BIN/usb-notification-watcher.sh" \
              "$BIN/usb-notification-action.sh"
    fi
    if [ -e /etc/udev/rules.d/99-usb-hotplug.rules ] || [ -e /usr/local/bin/on-usb-hotplug.sh ]; then
        echo "> Retrait de la règle udev de l'ancienne version (mot de passe demandé)"
        sudo rm -f /etc/udev/rules.d/99-usb-hotplug.rules /usr/local/bin/on-usb-hotplug.sh
        sudo udevadm control --reload-rules
    fi
}

if [ "$1" = "--uninstall" ]; then
    systemctl --user disable --now storage-notification.service 2>/dev/null || true
    rm -f "$UNITS/storage-notification.service" "$BIN/storage-notification.py"
    systemctl --user daemon-reload
    echo "Désinstallé."
    exit 0
fi

if ! python3 -c "import gi; gi.require_version('Gio', '2.0')" 2>/dev/null; then
    echo "> python3-gi manque : installation (mot de passe demandé)"
    sudo apt install -y python3-gi
fi

remove_legacy
mkdir -p "$BIN" "$UNITS"
install -m 755 storage-notification.py "$BIN/storage-notification.py"
install -m 644 storage-notification.service "$UNITS/storage-notification.service"
systemctl --user daemon-reload
systemctl --user enable --now storage-notification.service
systemctl --user restart storage-notification.service

echo "Installé. Notification d'essai :"
python3 "$BIN/storage-notification.py" --test
echo "Branche une clé USB pour voir la vraie."
