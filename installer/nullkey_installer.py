#!/usr/bin/env python3
"""Interactive installer for NullKey's existing QML resources."""

from __future__ import annotations

import argparse
import json
import os
import platform
import shlex
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path


SOURCE = Path(__file__).resolve().parent.parent
REGISTRY = SOURCE / "data/registry.json"
APP_NAME = "NullKey"
RUNTIME_PACKAGES = {
    "arch": ["qt5-declarative", "qt5-quickcontrols2"],
}


def read_json(path: Path):
    with path.open(encoding="utf-8") as stream:
        return json.load(stream)


def modules_for_platform(kind: str, platform_id: str):
    registry = read_json(REGISTRY)
    result = []
    for module_id in registry.get(kind, []):
        path = SOURCE / registry.get("moduleRoot", "modules") / kind / module_id / "module.json"
        if not path.is_file():
            continue
        metadata = read_json(path)
        shortcut = metadata.get("shortcutFiles", {}).get(platform_id)
        data_path = ((SOURCE / metadata.get("sourceDataRoot", "") / shortcut)
                     if kind == "dotfiles" and shortcut else path.parent / shortcut if shortcut else None)
        if (metadata.get("available", True) is not False
                and platform_id in metadata.get("platforms", [])
                and data_path and data_path.is_file()):
            result.append((module_id, metadata.get("name", module_id)))
    return result


def compatible_applications(platform_id, environment_ids):
    modules = modules_for_platform("applications", platform_id)
    if not environment_ids:
        return modules
    registry = read_json(REGISTRY)
    supported = set()
    matched_environment = False
    for environment_id in environment_ids:
        path = SOURCE / registry.get("moduleRoot", "modules") / "environments" / environment_id / "module.json"
        if path.is_file():
            matched_environment = True
            application_ids = read_json(path).get("applicationIds", [])
            if not application_ids:
                return modules
            supported.update(application_ids)
    if not matched_environment:
        return modules
    return [item for item in modules if item[0] in supported]


def validate_selection(selected):
    if selected.get("platformId", "linux") != "linux":
        raise RuntimeError("This release installs Linux modules only.")
    if selected.get("environment", "hyprland") != "hyprland":
        raise RuntimeError("This release installs the Hyprland environment only.")
    if any(value != "hyprland" for value in selected.get("environments", [])):
        raise RuntimeError("Only the Hyprland environment is available.")
    applications = list(dict.fromkeys(selected.get("applications", [])))
    available = dict(modules_for_platform("applications", "linux"))
    invalid = sorted(set(applications) - set(available))
    if invalid:
        raise RuntimeError("Applications without active Linux shortcut data: " + ", ".join(invalid))
    dotfiles = list(dict.fromkeys(selected.get("dotfiles", [])))
    available_dotfiles = dict(modules_for_platform("dotfiles", "linux"))
    invalid_dotfiles = sorted(set(dotfiles) - set(available_dotfiles))
    if invalid_dotfiles:
        raise RuntimeError("Dotfiles without active Linux shortcut data: " + ", ".join(invalid_dotfiles))
    return {"schemaVersion": 1, "mode": "selected", "platformId": "linux",
            "environment": "hyprland", "applications": applications, "dotfiles": dotfiles}


def detect_platform(system_name=None, os_release=None, machine=None):
    system_name = system_name or platform.system()
    machine = machine or platform.machine()
    if system_name != "Linux":
        return {"os": system_name.lower(), "supported": False, "family": None,
                "architecture": machine, "name": system_name, "package_manager": "None",
                "unsupported_reason": "Only Arch-based Linux is supported."}
    release = os_release or {}
    like = (release.get("ID", "") + " " + release.get("ID_LIKE", "")).lower().split()
    if release.get("ID", "").lower() in ("arch", "manjaro", "endeavouros", "garuda") or "arch" in like:
        return {"os": "linux", "supported": True, "family": "arch", "architecture": machine,
                "name": release.get("PRETTY_NAME", "Arch-based Linux"),
                "package_manager": "pacman" if shutil.which("pacman") else "pacman (not found)"}
    return {"os": "linux", "supported": False, "family": None, "architecture": machine,
            "name": release.get("PRETTY_NAME", "Linux"), "package_manager": "None",
            "unsupported_reason": "Only Arch-based Linux distributions are supported."}


def os_info(system_name=None, os_release=None, machine=None):
    values = {}
    system_name = system_name or platform.system()
    if system_name == "Linux":
        if os_release is None:
            try:
                for line in Path("/etc/os-release").read_text(encoding="utf-8").splitlines():
                    if "=" in line:
                        key, value = line.split("=", 1)
                        values[key] = value.strip().strip('"')
            except OSError:
                pass
        else:
            values = dict(os_release)
    result = detect_platform(system_name, values, machine)
    result.update({
        "session": os.environ.get("XDG_CURRENT_DESKTOP") or os.environ.get("DESKTOP_SESSION") or "Unknown",
        "session_type": os.environ.get("XDG_SESSION_TYPE", "unknown").lower(),
    })
    return result


def qml_probe(qmlscene: str | None):
    if not qmlscene:
        return False, "Qt 5 qmlscene was not found in PATH."
    env = os.environ.copy()
    env["QML_XHR_ALLOW_FILE_READ"] = "1"
    with tempfile.TemporaryDirectory(prefix="nullkey-qml-probe-") as config_home:
        env["XDG_CONFIG_HOME"] = config_home
        env["QT_QPA_PLATFORM"] = "offscreen"
        try:
            result = subprocess.run(
                [qmlscene, str(SOURCE / "installer/dependency-probe.qml")],
                cwd=SOURCE, env=env, text=True, stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT, timeout=15, check=False,
            )
        except (OSError, subprocess.TimeoutExpired) as exc:
            return False, str(exc)
    if result.returncode != 0:
        return False, result.stdout.strip() or f"qmlscene returned {result.returncode}"
    return True, "Qt 5 QML runtime and required imports are available."


class Dialog:
    def __init__(self):
        self.command = "built-in TUI"
        self._color = sys.stdout.isatty() and os.environ.get("NO_COLOR") is None
        if os.name == "nt" and self._color:
            try:
                import ctypes
                handle = ctypes.windll.kernel32.GetStdHandle(-11)
                mode = ctypes.c_uint()
                if ctypes.windll.kernel32.GetConsoleMode(handle, ctypes.byref(mode)):
                    ctypes.windll.kernel32.SetConsoleMode(handle, mode.value | 0x0004)
            except (AttributeError, OSError):
                self._color = False

    def _write(self, value):
        sys.stdout.write(value)
        sys.stdout.flush()

    def _style(self, text, code):
        return f"\033[{code}m{text}\033[0m" if self._color else text

    def _clear(self):
        self._write("\033[2J\033[H")

    def _panel(self, title, lines=(), footer="↑/↓ Navigate   Space Select   Enter Confirm   Esc Back"):
        width = max(54, min(shutil.get_terminal_size((80, 24)).columns - 4, 88))
        inner = width - 4
        self._clear()
        top = "┌" + "─" * (width - 2) + "┐"
        self._write(self._style(top + "\n", "36;1"))
        heading = f"  {title}"
        self._write(self._style("│" + heading[:inner].ljust(width - 2) + "│\n", "36;1"))
        self._write(self._style("├" + "─" * (width - 2) + "┤\n", "34"))
        for line in lines:
            line = str(line).replace("\t", "    ")[:inner]
            self._write("│ " + line.ljust(width - 4) + " │\n")
        self._write(self._style("├" + "─" * (width - 2) + "┤\n", "34"))
        self._write(self._style("│ " + footer[:inner].ljust(width - 4) + " │\n", "2"))
        self._write(self._style("└" + "─" * (width - 2) + "┘\n", "36;1"))

    def _key(self):
        if os.name == "nt":
            import msvcrt
            char = msvcrt.getwch()
            if char in ("\x00", "\xe0"):
                return {"H": "UP", "P": "DOWN"}.get(msvcrt.getwch(), "OTHER")
            return {"\r": "ENTER", "\x1b": "ESC", " ": "SPACE"}.get(char, char.lower())
        import select
        import termios
        import tty
        fd = sys.stdin.fileno()
        original = termios.tcgetattr(fd)
        try:
            tty.setraw(fd)
            char = os.read(fd, 1)
            if char == b"\x1b":
                ready, _, _ = select.select([fd], [], [], 0.035)
                if ready:
                    suffix = os.read(fd, 2)
                    return {b"[A": "UP", b"[B": "DOWN", b"[C": "RIGHT", b"[D": "LEFT"}.get(suffix, "ESC")
                return "ESC"
            return {b"\r": "ENTER", b"\n": "ENTER", b" ": "SPACE", b"\x03": "CTRL_C"}.get(char, char.decode("utf-8", "ignore").lower())
        finally:
            termios.tcsetattr(fd, termios.TCSADRAIN, original)

    @staticmethod
    def require_interactive():
        if not (sys.stdin.isatty() and sys.stdout.isatty()):
            raise RuntimeError("NullKey Setup needs an interactive terminal (stdin and stdout must both be TTYs).")

    def splash(self):
        logo = [
            " _   _ _   _ _     _     _  __ _____ __   __",
            "| \\ | | | | | |   | |   | |/ /| ____|\\ \\ / /",
            "|  \\| | | | | |   | |   | ' / |  _|   \\ V / ",
            "| |\\  | |_| | |___| |___| . \\ | |___   | |  ",
            "|_| \\_|\\___/|_____|_____|_|\\_\\|_____|  |_| ",
        ]
        self._clear()
        for line in logo:
            self._write(self._style(line + "\n", "36;1"))
            time.sleep(0.025)
        self._write("\n" + self._style("Developed by NullRoot\n", "35;1"))
        self._write("\nWelcome to NullKey Setup. Explore shortcuts for your environment and apps.\n")
        self._write("\nPress Enter to begin · Esc to quit\n")
        while True:
            key = self._key()
            if key == "ENTER":
                return True
            if key == "ESC":
                return False

    def status(self, lines):
        frames = "◐◓◑◒"
        for index, label in enumerate(lines):
            self._panel("Getting things ready", [f"{self._style(frames[index % len(frames)], '36;1')}  {label} …"])
            time.sleep(0.11)
            self._panel("Getting things ready", [f"{self._style('✓', '32;1')}  {label}"])
            time.sleep(0.07)

    def msg(self, text, height=12, width=72):
        lines = text.splitlines() or [""]
        self._panel("NullKey Setup", lines, "Enter Continue   ·   Esc Back")
        while True:
            key = self._key()
            if key == "ENTER":
                return True
            if key == "ESC":
                return False

    def checklist(self, title, entries, selected=None):
        # Selection is always explicit for a fresh setup; caller state is used only after Back.
        available = {item_id for item_id, _ in entries}
        chosen = set(selected or ()) & available
        cursor = 0
        offset = 0
        while True:
            height = shutil.get_terminal_size((80, 24)).lines
            page = max(4, height - 9)
            if cursor < offset:
                offset = cursor
            elif cursor >= offset + page:
                offset = cursor - page + 1
            rows = []
            for index in range(offset, min(len(entries), offset + page)):
                item_id, label = entries[index]
                marker = "x" if item_id in chosen else " "
                row = f"{'›' if index == cursor else ' '} [{marker}] {label}"
                rows.append(self._style(row, "36;1" if index == cursor else "0"))
            rows += ["", f"Selected: {len(chosen)}"]
            self._panel(title, rows)
            key = self._key()
            if key == "UP" and entries:
                cursor = (cursor - 1) % len(entries)
            elif key == "DOWN" and entries:
                cursor = (cursor + 1) % len(entries)
            elif key == "SPACE" and entries:
                item_id = entries[cursor][0]
                chosen.symmetric_difference_update((item_id,))
            elif key == "ENTER":
                return [item_id for item_id, _ in entries if item_id in chosen]
            elif key == "ESC":
                return None
            elif key == "CTRL_C":
                raise RuntimeError("Setup cancelled.")

    def menu(self, title, entries):
        cursor = 0
        while True:
            rows = [self._style(("› " if i == cursor else "  ") + label, "36;1" if i == cursor else "0")
                    for i, (_, label) in enumerate(entries)]
            self._panel(title, rows)
            key = self._key()
            if key == "UP": cursor = (cursor - 1) % len(entries)
            elif key == "DOWN": cursor = (cursor + 1) % len(entries)
            elif key == "ENTER": return entries[cursor][0]
            elif key == "ESC": return None

    def yesno(self, text):
        choice = 0
        while True:
            options = ["Install / Continue", "Go back"]
            lines = text.splitlines() + [""]
            lines.extend(self._style(("› " if index == choice else "  ") + option,
                                     "36;1" if index == choice else "0")
                         for index, option in enumerate(options))
            self._panel("Confirm", lines, "↑/↓ Choose   Enter Confirm   Esc Back")
            key = self._key()
            if key in ("UP", "DOWN"): choice = 1 - choice
            elif key == "ENTER": return choice == 0
            elif key == "ESC": return False

    def gauge(self, message, action):
        self._panel("Installing NullKey", [message, "Preparing installation …"])
        def update(pct, label):
            bar_width = 32
            filled = max(0, min(bar_width, int(bar_width * pct / 100)))
            bar = self._style("█" * filled, "36;1") + "░" * (bar_width - filled)
            self._panel("Installing NullKey", [f"[{bar}] {pct:3d}%", label])
        result = action(update)
        update(100, "Installation files are ready.")
        return result


def xdg_config_base():
    if hasattr(os, "geteuid") and os.geteuid() == 0 and os.environ.get("SUDO_USER"):
        try:
            import pwd
            invoking_user = pwd.getpwnam(os.environ["SUDO_USER"])
            return Path(os.environ.get("SUDO_XDG_CONFIG_HOME", str(Path(invoking_user.pw_dir) / ".config"))).expanduser()
        except KeyError:
            pass
    return Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config"))).expanduser()


def settings_file(config_base: Path):
    return config_base / "nullkey/QtProject/QtQmlViewer.conf"


def current_selection(config_base: Path):
    path = settings_file(config_base)
    if not path.is_file():
        return None
    in_category = False
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.startswith("[") and line.endswith("]"):
            in_category = line == "[MacKey]"
        elif in_category and line.split("=", 1)[0].strip() == "installedModulesJson" and "=" in line:
            try:
                value = json.loads(line.split("=", 1)[1].strip())
                return json.loads(value) if isinstance(value, str) else value
            except (json.JSONDecodeError, TypeError):
                return None
    return None


def seed_selection(config_base: Path, selected):
    path = settings_file(config_base)
    path.parent.mkdir(parents=True, exist_ok=True)
    existing = path.read_text(encoding="utf-8") if path.exists() else ""
    lines = existing.splitlines()
    indices = {}
    category_start = -1
    category_end = -1
    in_category = False
    for index, line in enumerate(lines):
        if line.startswith("[") and line.endswith("]"):
            if in_category and category_end < 0:
                category_end = index
            in_category = line == "[MacKey]"
            if in_category:
                category_start = index
        elif in_category and "=" in line:
            key = line.split("=", 1)[0].strip()
            if key in ("installedModulesJson", "activeDotfile"):
                indices[key] = index
    manifest = json.dumps({"schemaVersion": 1, "mode": "selected", "platformId": "linux",
                           "environment": "hyprland", "applications": selected["applications"],
                           "dotfiles": selected["dotfiles"]}, separators=(",", ":"))
    escaped = manifest.replace("\\", "\\\\").replace('"', '\\"')
    previous_active = ""
    in_settings_category = False
    for line in lines:
        if line.startswith("[") and line.endswith("]"):
            in_settings_category = line == "[MacKey]"
            continue
        if not in_settings_category:
            continue
        if line.split("=", 1)[0].strip() == "activeDotfile" and "=" in line:
            raw_active = line.split("=", 1)[1].strip()
            try:
                previous_active = json.loads(raw_active)
            except (json.JSONDecodeError, TypeError):
                previous_active = raw_active.strip('"')
            break
    selected_dotfiles = selected["dotfiles"]
    active_dotfile = previous_active if previous_active in selected_dotfiles else (selected_dotfiles[0] if selected_dotfiles else "")
    if not existing:
        lines = ["[MacKey]"]
        category_start = 0
    elif not any(line == "[MacKey]" for line in lines):
        lines.extend(["", "[MacKey]"])
        category_start = len(lines) - 1
    if category_end < 0:
        category_end = len(lines)
    settings = {
        "installedModulesJson": f'installedModulesJson="{escaped}"',
        "activeDotfile": "activeDotfile=" + json.dumps(active_dotfile),
    }
    changed = False
    missing = []
    for key, setting in settings.items():
        if key in indices:
            changed = changed or lines[indices[key]] != setting
            lines[indices[key]] = setting
        else:
            missing.append(setting)
    if missing:
        lines[category_end:category_end] = missing
        changed = True
    path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")
    return changed


def desktop_entry(launcher: Path, icon: Path):
    exec_path = str(launcher).replace("\\", "\\\\").replace('"', '\\"').replace("%", "%%")
    return "\n".join([
        "[Desktop Entry]", "Type=Application", "Version=1.0", "Name=NullKey",
        "Comment=Explore keyboard shortcuts and visualize key bindings",
        f'Exec="{exec_path}"', f"Icon={icon}", "Terminal=false",
        "Categories=Utility;Education;", "StartupNotify=true", "",
    ])


def generated_launcher(app_dir: Path):
    return f'''#!/bin/sh
set -eu
APP_DIR={shlex.quote(str(app_dir))}
export QML_XHR_ALLOW_FILE_READ=1
BASE_CONFIG="${{XDG_CONFIG_HOME:-$HOME/.config}}"
export XDG_CONFIG_HOME="$BASE_CONFIG/nullkey"
exec qmlscene --apptype gui "$APP_DIR/main.qml" "$@"
'''


def copy_resources(app_dir: Path, update, selected):
    app_dir.mkdir(parents=True, exist_ok=True)
    selection = validate_selection(selected)
    selected_apps = set(selection["applications"])
    selected_dotfiles = set(selection["dotfiles"])
    selected_environments = {"hyprland"}
    modules_root = SOURCE / read_json(REGISTRY).get("moduleRoot", "modules")
    def ignore(directory, names):
        ignored = set(shutil.ignore_patterns(
            ".git", ".agents", ".codex", "__pycache__", "*.pyc", "README.md",
            "CODEX_PROGRESS.md", "docs", "schemas", "tools", "installer", "packaging", ".pytest_cache",
        )(directory, names))
        current = Path(directory)
        if current == modules_root / "applications":
            ignored.update(set(names) - selected_apps)
        elif current == modules_root / "environments":
            ignored.update(set(names) - selected_environments)
        elif current == modules_root / "dotfiles":
            ignored.update(set(names) - selected_dotfiles)
        elif current == SOURCE / "data/environments":
            ignored.update(set(names) - selected_environments - selected_dotfiles)
        else:
            for dotfile_id in selected_dotfiles:
                dotfile_root = SOURCE / "data/environments" / dotfile_id
                if current == dotfile_root:
                    ignored.update(set(names) - {"linux", "references", "module.json"})
        return ignored

    shutil.copytree(SOURCE, app_dir, dirs_exist_ok=True, ignore=ignore)
    write_file(app_dir / "data/installed-modules.json", json.dumps(selection, indent=2) + "\n")
    update(58, "Bundled only selected modules and required application resources")


def write_file(path: Path, contents: str, executable=False):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(contents, encoding="utf-8")
    if executable:
        path.chmod(0o755)


def target_paths(scope: str, test_root: Path | None):
    if scope == "system":
        root = test_root or Path("/")
        return (root / "opt/nullkey", root / "usr/local/bin/nullkey",
                root / "usr/local/bin/uninstall-nullkey", root / "usr/share/applications/nullkey.desktop",
                root / "usr/share/applications")
    home = Path.home()
    return (home / ".local/share/nullkey", home / ".local/bin/nullkey",
            home / ".local/bin/uninstall-nullkey", home / ".local/share/applications/nullkey.desktop",
            home / ".local/share/applications")


def install(scope, selected, test_root=None, non_interactive=False, dialog=None):
    selected = validate_selection(selected)
    app_dir, launcher, uninstaller, desktop, desktop_dir = target_paths(scope, test_root)
    qmlscene = shutil.which("qmlscene") or "qmlscene"
    if not test_root and scope == "system" and os.geteuid() != 0:
        if not shutil.which("sudo"):
            raise RuntimeError("System-wide installation needs sudo, but sudo is not available.")
        subprocess.run(["sudo", "-v"], check=True)
        # Stage in the invoking user's temporary directory, then copy with the requested privilege.
        staged = Path(tempfile.mkdtemp(prefix="nullkey-install-")) / "nullkey"
        try:
            copy_resources(staged, lambda *_: None, selected)
            install_staged_system(staged, app_dir, launcher, uninstaller, desktop, selected, qmlscene)
        finally:
            shutil.rmtree(staged.parent, ignore_errors=True)
        return app_dir, launcher, uninstaller, desktop

    def work(update):
        if app_dir.exists():
            shutil.rmtree(app_dir)
        copy_resources(app_dir, update, selected)
        update(75, "Writing launcher and desktop entry")
        write_file(launcher, generated_launcher(app_dir), executable=True)
        write_file(desktop, desktop_entry(launcher, app_dir / "assets/icons/actions/keyboard.png"))
        write_file(uninstaller, uninstaller_script(scope, test_root), executable=True)
        update(88, "Saving selected module scope in your user configuration")
        if not test_root:
            config_base = xdg_config_base()
            config_file = settings_file(config_base)
            created = seed_selection(config_base, selected)
            if hasattr(os, "geteuid") and os.geteuid() == 0 and os.environ.get("SUDO_USER") and config_file.exists():
                import pwd
                invoking_user = pwd.getpwnam(os.environ["SUDO_USER"])
                os.chown(config_file.parent, invoking_user.pw_uid, invoking_user.pw_gid)
                if created:
                    os.chown(config_file, invoking_user.pw_uid, invoking_user.pw_gid)
        marker = {"application": "NullKey", "scope": scope, "appDir": str(app_dir),
                  "installedModules": selected,
                  "launcher": str(launcher), "uninstaller": str(uninstaller), "desktop": str(desktop)}
        write_file(app_dir / ".nullkey-install.json", json.dumps(marker, indent=2) + "\n")
        update(95, "Checking installed resources")
        return app_dir, launcher, uninstaller, desktop

    if not non_interactive and dialog:
        return dialog.gauge("Bundling QML, shortcut data, and keyboard layouts", work)
    return work(lambda *_: None)


def install_staged_system(staged, app_dir, launcher, uninstaller, desktop, selected, qmlscene):
    # A single sudo invocation performs only the explicit application-file installation.
    helper = staged.parent / "install-system.py"
    helper.write_text(
        "import json, pathlib, shutil, sys\n"
        "staged, app, launch, uninstall, desktop, source, selection = sys.argv[1:]\n"
        "staged, app = pathlib.Path(staged), pathlib.Path(app)\n"
        "if app.exists(): shutil.rmtree(app)\n"
        "shutil.copytree(staged, app, dirs_exist_ok=True)\n"
        "def put(path, data, executable=False):\n"
        " p=pathlib.Path(path); p.parent.mkdir(parents=True, exist_ok=True); p.write_text(data); p.chmod(0o755 if executable else 0o644)\n"
        "put(launch, open(source + '/.launcher').read(), True)\n"
        "put(uninstall, open(source + '/.uninstaller').read(), True)\n"
        "put(desktop, open(source + '/.desktop').read())\n"
        "put(str(app / '.nullkey-install.json'), json.dumps({'application':'NullKey','scope':'system','appDir':str(app),'launcher':launch,'uninstaller':uninstall,'desktop':desktop,'installedModules':json.loads(selection)}, indent=2) + '\\n')\n"
    )
    side = staged.parent
    write_file(side / ".launcher", generated_launcher(app_dir))
    write_file(side / ".uninstaller", uninstaller_script("system", None), executable=True)
    write_file(side / ".desktop", desktop_entry(launcher, app_dir / "assets/icons/actions/keyboard.png"))
    # Pass a strict argv list and use sudo for the helper only after the wizard's final confirmation.
    subprocess.run(["sudo", sys.executable, str(helper), str(staged), str(app_dir), str(launcher),
                    str(uninstaller), str(desktop), str(side), json.dumps(selected)], check=True)
    seed_selection(xdg_config_base(), selected)


def verify_installed(app_dir: Path, launcher: Path, desktop: Path, selected, timeout=2.0, launch=True):
    """Verify data at the installed prefix and briefly start the installed launcher."""
    if not app_dir.is_dir() or not launcher.is_file() or not desktop.is_file():
        raise RuntimeError("Installed application files, launcher, or desktop entry are missing.")
    registry = read_json(app_dir / "data/registry.json")
    manifest = read_json(app_dir / "data/installed-modules.json")
    expected_scope = validate_selection(selected)
    if manifest != expected_scope:
        raise RuntimeError("Installed module manifest does not match the installation selections.")
    installed_scopes = {"applications": expected_scope["applications"], "environments": ["hyprland"],
                        "dotfiles": expected_scope["dotfiles"]}
    for module_kind, selected_ids_list in installed_scopes.items():
        allowed = set(registry.get(module_kind, []))
        selected_ids = set(selected_ids_list)
        module_root = app_dir / registry.get("moduleRoot", "modules") / module_kind
        present_ids = {path.name for path in module_root.iterdir() if path.is_dir()}
        if present_ids != selected_ids:
            raise RuntimeError(f"Installed {module_kind} do not match the selected module scope.")
        for module_id in selected_ids_list:
            if module_id not in allowed:
                raise RuntimeError(f"Selected {module_kind[:-1]} ID is not registered: {module_id}")
            metadata = read_json(app_dir / "modules" / module_kind / module_id / "module.json")
            rel = metadata.get("shortcutFiles", {}).get("linux")
            if not rel:
                raise RuntimeError(f"Selected module has no {expected_scope['platformId']} shortcut data: {module_id}")
            data_path = (app_dir / metadata.get("sourceDataRoot", "") / rel
                         if module_kind == "dotfiles" else app_dir / "modules" / module_kind / module_id / rel)
            records = read_json(data_path)
            if not isinstance(records, list):
                raise RuntimeError(f"Shortcut data is not a JSON array: {module_id}")
    keyboard_ids = registry.get("keyboards", [])
    if not keyboard_ids:
        raise RuntimeError("The installed registry has no keyboard layout IDs.")
    for layout_id in keyboard_ids:
        layout = read_json(app_dir / "data/keyboards/geometry" / f"{layout_id}.json")
        if not layout.get("keys"):
            raise RuntimeError(f"Keyboard geometry did not load: {layout_id}")

    if not launch:
        return

    env = os.environ.copy()
    env["QML_XHR_ALLOW_FILE_READ"] = "1"
    env["QT_QPA_PLATFORM"] = "offscreen"
    try:
        process = subprocess.Popen([str(launcher)], cwd=app_dir, env=env,
                                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                   text=True, start_new_session=True)
        try:
            return_code = process.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            process.terminate()
            try:
                output, _ = process.communicate(timeout=3)
            except subprocess.TimeoutExpired:
                process.kill()
                output, _ = process.communicate()
            if output and any(token in output.lower() for token in ("is not installed", "is not a type", "failed to load", "referenceerror", "typeerror")):
                raise RuntimeError("The installed launcher reported a QML startup error:\n" + output)
            print("Installed launcher started and remained running.")
            return
        output = process.stdout.read() if process.stdout else ""
        raise RuntimeError(f"Installed launcher exited during startup (status {return_code}).\n{output}")
    except OSError as exc:
        raise RuntimeError(f"Could not start the installed launcher: {exc}") from exc


def uninstaller_script(scope, test_root):
    # The generated script validates the install marker before removing application paths.
    root_arg = f"--test-root {json.dumps(str(test_root))}" if test_root else ""
    return f'''#!/usr/bin/env python3
import argparse, json, os, shutil, subprocess, sys
from pathlib import Path
p=argparse.ArgumentParser(description="Remove NullKey application files; preserve user settings.")
p.add_argument("--remove-config", action="store_true", help="also remove ~/.config/nullkey after confirmation")
p.add_argument("--yes", action="store_true", help="skip the confirmation prompt")
p.add_argument("--test-root", type=Path, help=argparse.SUPPRESS)
a=p.parse_args()
test_root=a.test_root
app=Path({json.dumps(str(target_paths(scope, None)[0]))})
launcher=Path({json.dumps(str(target_paths(scope, None)[1]))})
uninstaller=Path({json.dumps(str(target_paths(scope, None)[2]))})
desktop=Path({json.dumps(str(target_paths(scope, None)[3]))})
if test_root:
    app=test_root / "opt/nullkey"; launcher=test_root / "usr/local/bin/nullkey"; uninstaller=test_root / "usr/local/bin/uninstall-nullkey"; desktop=test_root / "usr/share/applications/nullkey.desktop"
marker=app / ".nullkey-install.json"
if not marker.is_file():
    print("NullKey install marker is missing; refusing to remove unverified paths.", file=sys.stderr); sys.exit(1)
record=json.loads(marker.read_text())
if (record.get("application") != "NullKey"
        or Path(record.get("appDir", "")).resolve() != app.resolve()
        or Path(record.get("launcher", "")).resolve() != launcher.resolve()
        or Path(record.get("uninstaller", "")).resolve() != uninstaller.resolve()
        or Path(record.get("desktop", "")).resolve() != desktop.resolve()):
    print("Install marker does not match this NullKey destination; refusing removal.", file=sys.stderr); sys.exit(1)
if not a.yes:
    answer=input("Remove NullKey application files? User settings and data will be preserved. [y/N] ").lower() == "y"
    if not answer: sys.exit(0)
config=Path(os.environ.get("XDG_CONFIG_HOME",str(Path.home()/".config"))) / "nullkey"
remove_config=False
if a.remove_config:
    remove_config=input("Also remove user configuration at " + str(config) + "? This cannot be undone. [y/N] ").lower() == "y"
if os.geteuid() != 0 and not test_root and {json.dumps(scope)} == "system":
    command=shutil.which("sudo")
    if not command: print("System-wide uninstall needs sudo.", file=sys.stderr); sys.exit(1)
    subprocess.run([command,"-v"], check=True)
    if remove_config and config.exists(): shutil.rmtree(config)
    sys.exit(subprocess.run([command,sys.executable,__file__,"--yes"]).returncode)
for path in (app, launcher, uninstaller, desktop):
    if path.is_dir(): shutil.rmtree(path)
    elif path.exists(): path.unlink()
print("Removed NullKey application files.")
if remove_config and config.exists(): shutil.rmtree(config)
if not remove_config: print("User settings/data were preserved.")
else: print("User configuration was explicitly removed.")
'''


def missing_package_names(system, probe_ok):
    missing = []
    if not shutil.which("qmlscene"):
        missing.extend(RUNTIME_PACKAGES.get(system["family"], ["Qt 5 qmlscene and the required Qt Quick modules"]))
    elif not probe_ok:
        output = system.get("probe_output", "")
        module_packages = {
            "QtQuick": "qt5-declarative",
            "QtQuick.Controls": "qt5-quickcontrols2",
            "QtQuick.Layouts": "qt5-declarative",
            "QtQuick.Window": "qt5-declarative",
            "Qt.labs.settings": "qt5-declarative",
        }
        import re
        absent = re.findall(r'module "([^"]+)" is not installed', output)
        resolved = [module_packages[name] for name in absent if name in module_packages]
        missing.extend(resolved or RUNTIME_PACKAGES.get(system["family"], ["Qt 5 QML runtime modules (see the reported import error)"]))
    session_type = system.get("session_type")
    if session_type == "wayland" or os.environ.get("WAYLAND_DISPLAY"):
        if not platform_plugin_available("wayland"):
            package = "qt5-wayland" if system["family"] == "arch" else None
            missing.append(package or "Qt 5 Wayland platform plugin (qt5-wayland)")
    elif session_type == "x11" or os.environ.get("DISPLAY"):
        if not platform_plugin_available("xcb"):
            package = "qt5-base" if system["family"] == "arch" else None
            missing.append(package or "Qt 5 XCB platform plugin")
    return list(dict.fromkeys(missing))


def platform_plugin_available(plugin):
    qml_roots = [Path("/usr/lib/qt/plugins/platforms"), Path("/usr/lib/qt5/plugins/platforms"),
                 Path("/usr/lib/x86_64-linux-gnu/qt5/plugins/platforms"),
                 Path("/usr/lib/aarch64-linux-gnu/qt5/plugins/platforms")]
    configured = os.environ.get("QT_PLUGIN_PATH", "")
    qml_roots.extend(Path(path) / "platforms" for path in configured.split(os.pathsep) if path)
    configured_platforms = os.environ.get("QT_QPA_PLATFORM_PLUGIN_PATH", "")
    qml_roots.extend(Path(path) for path in configured_platforms.split(os.pathsep) if path)
    return any(any(path.glob(f"libq{plugin}*.so")) for path in qml_roots if path.is_dir())


def package_command(system, packages):
    if system["family"] == "arch":
        if not shutil.which("pacman"):
            return []
        return ([] if os.geteuid() == 0 else ["sudo"]) + ["pacman", "-S", "--needed", *packages]
    return []


def check_install_destination(scope, test_root=None):
    app_dir, launcher, uninstaller, desktop, _ = target_paths(scope, test_root)
    existing_paths = [path for path in (app_dir, launcher, uninstaller, desktop) if path.exists()]
    if not existing_paths:
        return
    marker_path = app_dir / ".nullkey-install.json"
    if not marker_path.is_file():
        raise RuntimeError("An install destination already exists without a NullKey marker; refusing to overwrite it.")
    try:
        marker = read_json(marker_path)
    except (OSError, json.JSONDecodeError) as exc:
        raise RuntimeError("The existing NullKey install marker is unreadable; refusing to overwrite it.") from exc
    expected = {"appDir": app_dir, "launcher": launcher, "uninstaller": uninstaller, "desktop": desktop}
    if marker.get("application") != "NullKey" or any(
            Path(marker.get(key, "")).resolve() != path.resolve() for key, path in expected.items()):
        raise RuntimeError("Existing NullKey installation metadata does not match these destinations; refusing to overwrite it.")


def run_wizard(args):
    dialog = Dialog()
    if not args.non_interactive:
        dialog.require_interactive()
        if not dialog.splash():
            return 0
    system = os_info()
    if not args.non_interactive:
        dialog.status(["System detected", "Loading module registry"])
    if not system["supported"]:
        message = f"Unsupported platform: {system['name']}\n\nNullKey Setup supports Arch-based Linux only. No packages were changed."
        if not args.non_interactive:
            dialog.msg(message)
            return 1
        raise RuntimeError(message)
    platform_id = "linux"
    qmlscene = shutil.which("qmlscene")
    probe_ok, probe_message = qml_probe(qmlscene)
    system["probe_output"] = probe_message
    missing = missing_package_names(system, probe_ok)
    if not args.non_interactive:
        dialog.status(["Runtime dependency check complete"])
    registry = read_json(REGISTRY)
    if args.non_interactive:
        selected = {"applications": list(args.applications or []), "dotfiles": list(args.dotfiles or [])}
        return complete_install(args, system, selected, missing, probe_ok)

    args.applications = []
    args.dotfiles = []
    phase = 1
    while True:
        if phase == 0:
            text = ("Welcome to NullKey Setup\n\n"
                    "This installs the NullKey shortcut explorer and its existing bundled data. "
                    "Environment: Hyprland · Platform: Linux. Application selections enable shortcut datasets; "
                    "they do not install third-party apps.\n\n"
                    "Use the arrow keys to navigate, Space to select, Enter to continue, and Esc to go back.")
            if dialog.msg(text): phase = 1
            else: return 0
        elif phase == 1:
            detail = (f"System: {system['name']}\nArchitecture: {system['architecture']}\n"
                      f"Desktop/session: {system['session']} ({system['session_type']})\nPackage manager: {system['package_manager']}\n"
                      "Platform: Linux\nEnvironment: Hyprland\n\n"
                      f"Qt 5 runtime: {'ready' if probe_ok else 'missing/incomplete'}\n"
                      f"Runtime check: {probe_message}\nInstaller interface: built-in terminal UI (ready)")
            if missing:
                detail += "\n\nMissing packages/tools:\n  " + "\n  ".join(missing)
                detail += "\n\nNullKey will ask before running pacman."
            else:
                detail += "\n\nRequired runtime dependencies are present."
            if dialog.msg(detail, 18, 78): phase = 2
            else: phase = 0
        elif phase == 2:
            choices = compatible_applications("linux", ["hyprland"])
            selected = dialog.checklist("Select Linux application shortcut contexts. This does not install those applications.", choices, args.applications)
            if selected is None: phase = 1
            else:
                args.applications = selected
                phase = 3
        elif phase == 3:
            choices = modules_for_platform("dotfiles", "linux")
            selected = dialog.checklist(
                "DE Dotfiles — choose shortcut collections to include in NullKey. These selections do not install or modify the corresponding desktop setup.",
                choices, args.dotfiles)
            if selected is None: phase = 2
            else:
                args.dotfiles = selected
                phase = 4
        elif phase == 4:
            scope = dialog.menu("Choose where NullKey files will be installed.", [
                ("system", "System-wide  /opt/nullkey (sudo required)"),
                ("user", "Only for this user  ~/.local/share/nullkey (no sudo)"),
            ])
            if scope is None: phase = 3
            elif scope == "system" and os.geteuid() != 0 and not shutil.which("sudo"):
                dialog.msg("System-wide installation requires sudo, but sudo was not found. Choose user-local installation or install sudo.")
            else:
                args.scope = scope
                phase = 5
        elif phase == 5:
            selected = {"applications": args.applications, "dotfiles": args.dotfiles}
            destination = "/opt/nullkey, /usr/local/bin/nullkey" if args.scope == "system" else "~/.local/share/nullkey, ~/.local/bin/nullkey"
            summary = (f"Host: {system['name']} ({system['architecture']})\nPlatform: Linux\nEnvironment: Hyprland\n"
                       f"Application datasets: {labels(selected['applications'], 'applications')}\n"
                       f"DE Dotfiles datasets: {labels(selected['dotfiles'], 'dotfiles')}\n"
                       f"Destination: {destination}\n"
                       "Desktop entry: system or user applications menu\n"
                       f"Dependency packages missing: {', '.join(missing) if missing else 'none'}\n\n"
                       + ("No application modules selected; NullKey will install with no application shortcut modules.\n\n" if not selected["applications"] else "")
                       + ("No DE Dotfiles selected.\n\n" if not selected["dotfiles"] else "")
                       + "No shortcut records are generated or copied into user data. Continue?")
            if dialog.yesno(summary):
                return complete_install(args, system, selected, missing, probe_ok, dialog)
            phase = 4


def labels(ids, kind):
    names = dict(modules_for_platform(kind, "linux"))
    return ", ".join(names.get(i, i) for i in ids) if ids else "None selected"


def complete_install(args, system, selected, missing, probe_ok, dialog=None):
    selected = validate_selection(selected)
    test_root = args.test_root
    check_install_destination(args.scope, test_root)
    if missing:
        packages = missing
        command = package_command(system, packages)
        if test_root:
            print("Safe test-prefix mode: runtime packages were not installed:", ", ".join(missing))
        else:
            if not command:
                message = "No safe package-manager mapping exists for this distribution. Install these dependencies manually:\n" + "\n".join(missing)
                if dialog:
                    dialog.msg(message, 18, 78)
                raise RuntimeError(message)
            if os.geteuid() != 0 and not shutil.which("sudo"):
                raise RuntimeError("Installing missing system runtime dependencies requires sudo. Install these packages manually:\n"
                                   + "\n".join(packages))
            if dialog and not dialog.yesno("Install the missing packages now?\n\n" + "\n".join(packages) + "\n\nCommand: " + " ".join(command)):
                raise RuntimeError("Installation cancelled because required dependencies remain missing.")
            subprocess.run(command, check=True)
            ok, message = qml_probe(shutil.which("qmlscene"))
            if not ok:
                raise RuntimeError("Dependencies remain unavailable after package installation: " + message)
    if not test_root and not probe_ok and not shutil.which("qmlscene"):
        raise RuntimeError("Cannot launch NullKey: qmlscene is unavailable.")
    if args.scope == "system" and not test_root and os.geteuid() != 0 and not shutil.which("sudo"):
        raise RuntimeError("System-wide installation requires sudo.")
    paths = install(args.scope, selected, test_root, args.non_interactive, dialog)
    verify_installed(paths[0], paths[1], paths[3], selected, launch=(not test_root or probe_ok))
    if test_root:
        print("Installed test copy verified:", paths[0])
        return 0
    if dialog:
        dialog.msg("NullKey installed and verified.\n\nLaunch it from your applications menu or run nullkey.\n\nUser settings: ~/.config/nullkey/QtProject/QtQmlViewer.conf", 14, 76)
    else:
        print("NullKey installed and verified from:", paths[0])
    return 0


def main():
    parser = argparse.ArgumentParser(description="Interactive NullKey terminal setup wizard")
    parser.add_argument("--test-root", type=Path, help="Install under a temporary prefix without sudo or host changes")
    parser.add_argument("--non-interactive", action="store_true", help=argparse.SUPPRESS)
    parser.add_argument("--scope", choices=("system", "user"), default="user", help=argparse.SUPPRESS)
    parser.add_argument("--applications", nargs="*", help=argparse.SUPPRESS)
    parser.add_argument("--dotfiles", nargs="*", help=argparse.SUPPRESS)
    args = parser.parse_args()
    if args.test_root:
        args.test_root = args.test_root.expanduser().resolve()
        args.scope = "system"
    try:
        if not (SOURCE / "data/registry.json").is_file():
            raise RuntimeError("Run this installer from a complete NullKey source tree.")
        # The installer needs Python's standard library only. Validate bundled JSON before copying.
        validator = SOURCE / "tools/validate_data.py"
        if validator.is_file():
            validation = subprocess.run([sys.executable, str(validator)], cwd=SOURCE, text=True,
                                        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, check=False)
            if validation.returncode:
                raise RuntimeError("Bundled data validation failed:\n" + validation.stdout)
        return run_wizard(args)
    except (RuntimeError, OSError, subprocess.CalledProcessError, subprocess.TimeoutExpired) as exc:
        if sys.stdin.isatty() and sys.stdout.isatty():
            try:
                Dialog().msg(f"Setup could not continue.\n\n{exc}")
            except (OSError, RuntimeError):
                print(f"NullKey installer: {exc}", file=sys.stderr)
        else:
            print(f"NullKey installer: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
