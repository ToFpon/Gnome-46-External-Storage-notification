#!/bin/bash

# Couleurs pour le terminal
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Installation des notifications USB pour Gnome 46 ===${NC}"

# 1. Vérification des dépendances
echo -e "\n> Vérification des dépendances..."
for pkg in inotify-tools libnotify-bin bc util-linux; do
    if ! command -v $pkg &> /dev/null; then
        echo -e "Installation de $pkg..."
        sudo apt update && sudo apt install -y $pkg
    fi
done

# 2. Création des dossiers locaux
echo -e "\n> Préparation des dossiers locaux..."
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.config/systemd/user"

# 3. Copie des fichiers Utilisateur (sans sudo)
echo -e "> Installation des scripts utilisateur..."
cp usb-notification-watcher.sh "$HOME/.local/bin/"
cp usb-notification-action.sh "$HOME/.local/bin/"
cp usb-notification-watcher.service "$HOME/.config/systemd/user/"

chmod +x "$HOME/.local/bin/usb-notification-watcher.sh"
chmod +x "$HOME/.local/bin/usb-notification-action.sh"

# 4. Copie des fichiers Système (nécessite sudo)
echo -e "> Installation des scripts système (sudo requis)..."
sudo cp on-usb-hotplug.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/on-usb-hotplug.sh

sudo cp 99-usb-hotplug.rules /etc/udev/rules.d/

# 5. Rechargement du système
echo -e "\n> Rechargement des services..."
sudo udevadm control --reload-rules
sudo udevadm trigger

systemctl --user daemon-reload
systemctl --user enable usb-notification-watcher.service
systemctl --user restart usb-notification-watcher.service

echo -e "\n${GREEN}=== Installation terminée avec succès ! ===${NC}"
echo -e "Branche une clé USB pour tester la notification."
