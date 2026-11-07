#!/usr/bin/env python3
"""Notification au branchement d'un stockage externe (clé USB, disque, carte SD, téléphone) pour
GNOME 46, qui ne le signale plus. Bouton « Ouvrir » : le gestionnaire de fichiers par défaut
(Nautilus, Odysseus…).

Service utilisateur, sans udev ni root : on écoute GIO (Gio.VolumeMonitor, comme Nautilus), qui
annonce le montage terminé avec le nom, l'icône et le dossier du support — téléphones (MTP) et
appareils photo compris. Notification par D-Bus (org.freedesktop.Notifications), sans dépendance
au-delà de python3-gi, présent sur toute installation GNOME.

  storage-notification.py           lance la surveillance (le service systemd le fait au démarrage)
  storage-notification.py --test    affiche une notification d'essai et quitte
"""

from __future__ import annotations

import locale
import os
import sys

import gi

gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib  # noqa: E402

APP_NAME = "Stockage externe"
SOUND = "/usr/share/sounds/zorin/stereo/device-added.oga"     # son de Zorin, s'il existe
TIMEOUT_MS = 10000                                            # la notification s'efface d'elle-même

_LANG = (locale.getlocale()[0] or os.environ.get("LANG", "")).lower()
FR = _LANG.startswith("fr")
DE = _LANG.startswith("de")


def _(fr: str, en: str, de: str) -> str:
    return fr if FR else de if DE else en


TITLE = _("Stockage externe connecté", "External storage connected", "Externer Speicher verbunden")
OPEN = _("Ouvrir", "Open", "Öffnen")


def icon_name(gicon) -> str:
    """Nom d'icône pour la notification (celle que GIO donne au support : clé, disque, carte SD,
    téléphone…)."""
    if isinstance(gicon, Gio.ThemedIcon):
        names = gicon.get_names()
        if names:
            return names[0]
    return "drive-removable-media"


def is_external(mount: Gio.Mount) -> bool:
    """Supports qu'on vient de brancher : amovibles (clé, disque USB, carte SD), téléphones et
    appareils photo. Pas les partitions internes ouvertes à la main, ni les partages réseau."""
    if mount.is_shadowed():
        return False
    root = mount.get_root()
    scheme = root.get_uri_scheme() if root is not None else ""
    if scheme in ("mtp", "gphoto2", "afc"):
        return True
    drive = mount.get_drive()
    if drive is None:
        return False
    return drive.is_removable() or drive.is_media_removable() or drive.can_eject()


def describe(mount: Gio.Mount) -> str:
    """« SANDISK (SanDisk Cruzer Blade) » : le nom du volume, puis celui de l'appareil s'il diffère."""
    name = mount.get_name() or ""
    drive = mount.get_drive()
    model = drive.get_name() if drive is not None else ""
    if model and model.lower() not in name.lower():
        return f"{name} ({model})" if name else model
    return name or model or _("Périphérique", "Device", "Gerät")


class Notifier:
    def __init__(self, loop: GLib.MainLoop):
        self.loop = loop
        self.bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
        self.targets: dict[int, str] = {}          # identifiant de notification → URI à ouvrir
        self.bus.signal_subscribe("org.freedesktop.Notifications", "org.freedesktop.Notifications",
                                  "ActionInvoked", "/org/freedesktop/Notifications", None,
                                  Gio.DBusSignalFlags.NONE, self._on_action)
        self.bus.signal_subscribe("org.freedesktop.Notifications", "org.freedesktop.Notifications",
                                  "NotificationClosed", "/org/freedesktop/Notifications", None,
                                  Gio.DBusSignalFlags.NONE, self._on_closed)

    def notify(self, body: str, icon: str, uri: str):
        hints = {"category": GLib.Variant("s", "device.added")}
        fm = Gio.AppInfo.get_default_for_type("inode/directory", False)
        if fm is not None and fm.get_id():
            # icône / nom de l'application dans la notification : le gestionnaire de fichiers choisi
            hints["desktop-entry"] = GLib.Variant("s", fm.get_id().removesuffix(".desktop"))
        if os.path.exists(SOUND):
            hints["sound-file"] = GLib.Variant("s", SOUND)
        # « default » : un clic sur la notification elle-même ouvre aussi le support
        actions = ["default", OPEN, "open", OPEN]
        params = GLib.Variant("(susssasa{sv}i)", (APP_NAME, 0, icon, TITLE, body, actions, hints, TIMEOUT_MS))
        self.bus.call("org.freedesktop.Notifications", "/org/freedesktop/Notifications",
                      "org.freedesktop.Notifications", "Notify", params, GLib.VariantType("(u)"),
                      Gio.DBusCallFlags.NONE, -1, None, self._sent, uri)

    def _sent(self, bus, res, uri):
        try:
            nid = bus.call_finish(res).unpack()[0]
        except GLib.Error as e:
            print("storage-notification : notification impossible :", e.message, file=sys.stderr)
            return
        self.targets[nid] = uri

    def _on_action(self, _bus, _sender, _path, _iface, _signal, params):
        nid, action = params.unpack()
        uri = self.targets.pop(nid, None)
        if uri and action in ("default", "open"):
            try:
                # gestionnaire de fichiers PAR DÉFAUT (inode/directory) : Nautilus, Odysseus…
                Gio.AppInfo.launch_default_for_uri(uri, None)
            except GLib.Error as e:
                print("storage-notification : ouverture impossible :", e.message, file=sys.stderr)

    def _on_closed(self, _bus, _sender, _path, _iface, _signal, params):
        nid, _reason = params.unpack()
        # GNOME envoie ActionInvoked avant NotificationClosed : on peut oublier la cible
        GLib.timeout_add(2000, lambda: (self.targets.pop(nid, None), False)[1])


def main() -> int:
    loop = GLib.MainLoop()
    notifier = Notifier(loop)
    if "--test" in sys.argv:
        notifier.notify("TEST (SanDisk Cruzer Blade)", "drive-removable-media-usb",
                        GLib.filename_to_uri(os.path.expanduser("~"), None))
        GLib.timeout_add(1500, lambda: (loop.quit(), False)[1])
        loop.run()
        return 0
    monitor = Gio.VolumeMonitor.get()

    def added(_monitor, mount):
        if not is_external(mount):
            return
        root = mount.get_root()
        notifier.notify(describe(mount), icon_name(mount.get_icon()), root.get_uri())
    monitor.connect("mount-added", added)
    # les supports déjà branchés au démarrage de la session ne sont pas annoncés : seulement les nouveaux
    loop.run()
    return 0


if __name__ == "__main__":
    sys.exit(main())
