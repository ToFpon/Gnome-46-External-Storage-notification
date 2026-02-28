#!/usr/bin/env bash

# Couleurs pour le terminal
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}Installation de BT-OSD (Lola) - Version Stable${NC}"

# 1. Nettoyage préventif des anciens fichiers conflictuels
echo -e "${BLUE}Nettoyage des anciennes configurations...${NC}"
# On tente de supprimer les anciens fichiers fixes qui causaient des erreurs de droits
rm -f /tmp/current_bt_name /tmp/current_bt_icon 2>/dev/null || echo -e "${RED}Note: Certains fichiers dans /tmp n'ont pas pu être nettoyés (déjà utilisés par root), mais la nouvelle version les ignorera.${NC}"

# 2. Création des dossiers locaux
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.config/systemd/user"

# 3. Copie du script principal
if [ -f "btnot.sh" ]; then
    cp btnot.sh "$HOME/.local/bin/btnot.sh"
    chmod +x "$HOME/.local/bin/btnot.sh"
    echo -e "${GREEN} -> Script copié dans ~/.local/bin/btnot.sh${NC}"
else
    echo -e "${RED}Erreur: btnot.sh introuvable dans le dossier actuel !${NC}"
    exit 1
fi

# 4. Création du fichier service systemd
cat <<EOF > "$HOME/.config/systemd/user/btnot.service"
[Unit]
Description=Service de notification Bluetooth et OSD Volume (Lola)
After=bluetooth.target

[Service]
ExecStart=$HOME/.local/bin/btnot.sh
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
EOF

echo -e "${GREEN} -> Service systemd créé.${NC}"

# 5. Activation et lancement
systemctl --user daemon-reload
systemctl --user enable btnot.service
systemctl --user restart btnot.service

echo -e "${BLUE}-------------------------------------------------------${NC}"
echo -e "${GREEN}Installation terminée avec succès !${NC}"
echo -e "Lola est prête. Connecte un appareil Bluetooth pour tester l'OSD."
echo -e "${BLUE}-------------------------------------------------------${NC}"
