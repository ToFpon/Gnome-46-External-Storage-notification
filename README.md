# Gnome 46 USB Connect Notification

Ce projet ajoute une notification interactive lors du branchement d'un support USB sur **Gnome 46** (testé sur Zorin OS 17). 

Contrairement aux notifications système standards, celle-ci permet d'ouvrir directement le dossier de la clé dans **Nautilus** via un bouton dédié, tout en gérant intelligemment les noms de périphériques et les points de montage avec espaces.

## ✨ Fonctionnalités

- **Détection intelligente** : Identifie le fabricant et le produit (ex: "Sony Storage Media").
- **Icônes adaptatives** : Affiche une icône différente pour les téléphones, disques SSD, cartes SD ou clés USB.
- **Action interactive** : Propose un bouton "Ouvrir dans Nautilus" directement dans la notification.
- **Gestion des espaces** : Supporte les noms de volumes contenant des espaces (ex: `Ma Cle USB`).
- **Découplage Système/Utilisateur** : Utilise une architecture robuste combinant `udev` (système) et un `watcher` (utilisateur) via `inotify`.

## 🛠️ Installation rapide

Clonez le dépôt et lancez simplement le script d'installation :

git clone [https://github.com/ToFpon/Gnome-46-USB-connect-notification.git](https://github.com/ToFpon/Gnome-46-USB-connect-notification.git)
```bash
cd Gnome-46-USB-connect-notification
chmod +x install.sh
./install.sh 
```

Le script s'occupera d'installer les dépendances (inotify-tools, libnotify-bin, bc), de copier les scripts et d'activer le service utilisateur.

## 🏗️ Architecture du projet

udev rules : Détecte l'ajout physique du périphérique.

on-usb-hotplug.sh : Script système qui identifie le matériel et crée un signal (trigger) dans /tmp.

usb-notification-watcher : Service utilisateur qui surveille le signal et attend que le montage soit effectif.

usb-notification-action.sh : Gère l'affichage de la notification et l'ouverture de Nautilus.

## 📝 Configuration
Les logs de débogage sont disponibles dans /tmp/usb-watcher-debug.log pour l'action utilisateur et /tmp/on-usb-hotplug.txt pour la partie système.
