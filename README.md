# Gnome 46 External Storage Notification

[English version below] | [Version française ci-dessous]

---

## 🇺🇸 English Version

GNOME 46 (Zorin OS 18, Ubuntu 24.04…) no longer shows a notification when you plug in external
storage. This small user service brings it back: USB key, external drive, SD card, smartphone (MTP)
or camera. An **Open** button (or a click on the notification) opens the device in your **default
file manager** — Nautilus, Odysseus, or whatever you chose.

## 📷 Screenshots:
<img width="328" height="110" alt="key-notif" src="https://github.com/user-attachments/assets/371f9fe1-fddc-4210-88dc-61322303c549" /><img width="328" height="110" alt="drive-notif" src="https://github.com/user-attachments/assets/7eded233-35b1-4496-a72e-32022f2890af" />
<img width="328" height="110" alt="sd-notif" src="https://github.com/user-attachments/assets/51f4c1d0-2d63-4a72-929b-f02e3f471e8c" /><img width="328" height="110" alt="phone-notif" src="https://github.com/user-attachments/assets/f0bb9109-4f7f-414b-81cd-ed994b4b3d74" />

## ✨ Features

- **Notified once the device is mounted**, with its name and model (e.g. "SANDISK (SanDisk Cruzer Blade)").
- **The device's own icon** (USB key, drive, SD card, phone…), as GNOME shows it.
- **Open** button: the default file manager (`inode/directory`), not hard-wired to Nautilus.
- **Phones and cameras** (MTP, PTP, iPhone) included.
- Internal partitions you open by hand and network shares are ignored.
- **No udev rule, no root, no polling**: a single Python script listening to GIO (`Gio.VolumeMonitor`,
  the same source Nautilus uses). Only dependency: `python3-gi`, already on every GNOME desktop.
- French, English and German messages (system language).

## 🛠️ Installation

```bash
git clone https://github.com/ToFpon/Gnome-46-External-Storage-notification.git
cd Gnome-46-External-Storage-notification
./install.sh
```

No `sudo` needed (except to install `python3-gi` if it is missing, or to remove the udev rule of the
old version). The script installs `~/.local/bin/storage-notification.py` and the user service
`storage-notification.service`, starts it, and shows a test notification. Plug in a USB key to see
the real one.

Uninstall: `./install.sh --uninstall`

Test notification at any time: `python3 ~/.local/bin/storage-notification.py --test`
Logs: `journalctl --user -u storage-notification`

## 🗄️ The old version (`legacy/`)

The first version (udev rule + trigger file in `/tmp` + inotify watcher + `notify-send`) is kept in
the `legacy/` folder. The new installer removes it automatically if it finds it. To install it
instead: `./install.sh --uninstall`, then `cd legacy && ./install.sh`.

---

## 🇫🇷 Version Française

GNOME 46 (Zorin OS 18, Ubuntu 24.04…) ne prévient plus quand on branche un stockage externe. Ce
petit service utilisateur le refait : clé USB, disque externe, carte SD, téléphone (MTP) ou appareil
photo. Le bouton **Ouvrir** (ou un clic sur la notification) ouvre le support dans le **gestionnaire
de fichiers par défaut** — Nautilus, Odysseus, ou celui que tu as choisi.

## ✨ Fonctionnalités

- **Notification une fois le support monté**, avec son nom et son modèle (ex. « SANDISK (SanDisk Cruzer Blade) »).
- **L'icône du support** (clé, disque, carte SD, téléphone…), celle que montre GNOME.
- Bouton **Ouvrir** : le gestionnaire de fichiers par défaut (`inode/directory`), plus seulement Nautilus.
- **Téléphones et appareils photo** (MTP, PTP, iPhone) compris.
- Les partitions internes ouvertes à la main et les partages réseau sont ignorés.
- **Ni règle udev, ni root, ni scrutation** : un seul script Python à l'écoute de GIO
  (`Gio.VolumeMonitor`, la même source que Nautilus). Seule dépendance : `python3-gi`, présent sur
  tout bureau GNOME.
- Messages en français, anglais et allemand (langue du système).

## 🛠️ Installation

```bash
git clone https://github.com/ToFpon/Gnome-46-External-Storage-notification.git
cd Gnome-46-External-Storage-notification
./install.sh
```

Pas besoin de `sudo` (sauf pour installer `python3-gi` s'il manque, ou retirer la règle udev de
l'ancienne version). Le script installe `~/.local/bin/storage-notification.py` et le service
utilisateur `storage-notification.service`, le démarre et affiche une notification d'essai. Branche
une clé USB pour voir la vraie.

Désinstaller : `./install.sh --uninstall`

Notification d'essai à tout moment : `python3 ~/.local/bin/storage-notification.py --test`
Journal : `journalctl --user -u storage-notification`

## 🗄️ L'ancienne version (`legacy/`)

La première version (règle udev + fichier signal dans `/tmp` + surveillance inotify + `notify-send`)
est gardée dans le dossier `legacy/`. Le nouvel installeur la retire tout seul s'il la trouve. Pour
l'installer à la place : `./install.sh --uninstall`, puis `cd legacy && ./install.sh`.
