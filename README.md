# Gnome 46 USB Connect Notification

[English version below] | [Version française ci-dessous]

---

## 🇺🇸 English Version

This project adds an interactive notification when plugging in a USB storage device or smartphone on **Gnome 46** (tested on Zorin OS 18). 

Unlike standard system notifications, this one allows you to open the device folder directly in **Nautilus** via a dedicated button. It intelligently handles device names, spaces in volume labels, and MTP (Smartphone) mount points.

## ✨ Features

- **Smart Detection**: Identifies manufacturer and product (e.g., "Sony Storage Media" or "Google Pixel 8a").
- **Adaptive Icons**: Displays specific icons for smartphones (MTP), SSDs, SD cards, or USB drives.
- **Interactive Action**: "Open in Nautilus" button directly within the notification.
- **MTP & NTFS Support**: Advanced detection for smartphones (via GVFS) and standard drives (NTFS, FAT32, EXT4).
- **System/User Decoupling**: Robust architecture combining `udev` (system level) and an `inotify` watcher (user level).

## 🛠️ Quick Installation

Clone the repository and run the installation script:

```bash
git clone [https://github.com/ToFpon/Gnome-46-USB-connect-notification.git](https://github.com/ToFpon/Gnome-46-USB-connect-notification.git)
cd Gnome-46-USB-connect-notification
chmod +x install.sh
./install.sh
```
The script will install dependencies (inotify-tools, libnotify-bin, bc), copy the files, and enable the user service.

## 🏗️ Project Architecture
udev rules: Detects the physical connection of the device.

on-usb-hotplug.sh: System script that identifies hardware and creates a trigger signal in /tmp.

usb-notification-watcher.sh: User service that monitors the signal and waits for the mount point to be ready.

usb-notification-action.sh: Handles the notification display and launches Nautilus.

## 📝 Configuration & Debugging
Debug logs are available in /tmp/usb-watcher.log to track the detection process and mount point discovery.

## 🇫🇷 Version Française
Ce projet ajoute une notification interactive lors du branchement d'un support USB ou d'un smartphone sur Gnome 46 (testé sur Zorin OS 18).

Contrairement aux notifications système standards, celle-ci permet d'ouvrir directement le dossier du périphérique dans Nautilus via un bouton dédié, tout en gérant intelligemment les noms de périphériques, les espaces et les points de montage MTP (Smartphones).

## ✨ Fonctionnalités

- **Détection intelligente : Identifie le fabricant et le produit (ex: "Sony Storage Media" ou "Google Pixel 8a").
- **Icônes adaptatives : Affiche une icône différente pour les téléphones (MTP), disques SSD, cartes SD ou clés USB.
- **Action interactive : Propose un bouton "Ouvrir dans Nautilus" directement dans la notification.
- **Support MTP & NTFS : Détection avancée pour les smartphones (via GVFS) et les disques standards (NTFS, FAT32, EXT4).
- **Découplage Système/Utilisateur : Architecture robuste combinant udev (système) et un watcher utilisateur via inotify.

## 🛠️ Installation rapide
Clonez le dépôt et lancez simplement le script d'installation :

```bash
git clone [https://github.com/ToFpon/Gnome-46-USB-connect-notification.git](https://github.com/ToFpon/Gnome-46-USB-connect-notification.git)
cd Gnome-46-USB-connect-notification
chmod +x install.sh
./install.sh
```
Le script s'occupera d'installer les dépendances (inotify-tools, libnotify-bin, bc), de copier les scripts et d'activer le service utilisateur.

## 🏗️ Architecture du projet
udev rules : Détecte l'ajout physique du périphérique.

on-usb-hotplug.sh : Script système qui identifie le matériel et crée un signal (trigger) dans /tmp.

usb-notification-watcher.sh : Service utilisateur qui surveille le signal et attend que le montage soit effectif.

usb-notification-action.sh : Gère l'affichage de la notification et l'ouverture de Nautilus.

## 📝 Configuration & Débogage
Les logs de débogage sont disponibles dans /tmp/usb-watcher.log pour suivre le processus de détection et de montage en temps réel.
