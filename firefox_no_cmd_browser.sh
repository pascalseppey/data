#!/bin/bash

# === CONFIGURATION DU PROXY IPRoyal ===
PROXY_HOST="geo.iproyal.com"
PROXY_PORT="12321"
PROXY_USER="Yz3XQbz7vR2z3qmo"
PROXY_PASS="rUwiPZvJ8YF5tR0b_country-ch"
SESSION_ID="agent$RANDOM"

# === PROFIL FIREFOX ===
PROFILE_NAME="stealth_agent"
PROFILE_DIR="$HOME/.mozilla/firefox/${PROFILE_NAME}.default-release"
EXT_ID="foxyproxy@eric.h.jung"
EXT_URL="https://addons.mozilla.org/firefox/downloads/file/4425860/foxyproxy_standard-8.10.xpi"
EXT_FILE="/tmp/foxyproxy.xpi"

# === INSTALLATION DES DÉPENDANCES ===
echo "[1/7] Installation des outils..."
apt update && apt install -y firefox x11vnc xvfb fluxbox curl unzip jq wget python3 python3-pip
pip3 install selenium webdriver-manager fake-useragent

# === TÉLÉCHARGEMENT FOXYPROXY ===
echo "[2/7] Téléchargement de FoxyProxy"
curl -sL "$EXT_URL" -o "$EXT_FILE"

# === CRÉATION DU PROFIL FIREFOX ===
echo "[3/7] Préparation du profil Firefox : $PROFILE_NAME"
mkdir -p "$PROFILE_DIR/extensions"
unzip -q "$EXT_FILE" -d /tmp/foxyproxy_extract
FOXY_ID=$(jq -r '.applications.gecko.id' /tmp/foxyproxy_extract/manifest.json)
mv "$EXT_FILE" "$PROFILE_DIR/extensions/$FOXY_ID.xpi"
rm -rf /tmp/foxyproxy_extract

# === CRÉATION DU SCRIPT PYTHON SELENIUM ===
echo "[4/7] Génération du script Selenium"
cat > /root/stealth_agent.py <<EOF
from selenium import webdriver
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.common.by import By
from fake_useragent import UserAgent
import time

ua = UserAgent()
user_agent = ua.random

options = Options()
options.set_preference("general.useragent.override", user_agent)
options.set_preference("network.proxy.type", 1)
options.set_preference("network.proxy.http", "$PROXY_HOST")
options.set_preference("network.proxy.http_port", int("$PROXY_PORT"))
options.set_preference("network.proxy.ssl", "$PROXY_HOST")
options.set_preference("network.proxy.ssl_port", int("$PROXY_PORT"))
options.set_preference("network.proxy.socks_remote_dns", True)
options.set_preference("signon.autologin.proxy", True)
options.set_preference("network.proxy.share_proxy_settings", True)
options.set_preference("network.proxy.username", "$PROXY_USER")
options.set_preference("network.proxy.password", "$PROXY_PASS")

profile_path = "$PROFILE_DIR"
driver = webdriver.Firefox(options=options, firefox_profile=webdriver.FirefoxProfile(profile_path))
driver.set_window_size(1280, 720)

# Lancement de sites pour vérification
sites = [
    "https://www.whatismybrowser.com/",
    "https://browserleaks.com/ip",
    "https://whoer.net"
]

for site in sites:
    driver.get(site)
    time.sleep(10)

input("\n[OK] Navigation manuelle possible. Fermez la fenêtre pour quitter.\n")
driver.quit()
EOF

# === LANCEMENT D'UN ENVIRONNEMENT GRAPHIQUE ===
echo "[5/7] Lancement de Xvfb et Fluxbox"
killall -q Xvfb fluxbox firefox x11vnc || true
Xvfb :1 -screen 0 1280x720x24 &
sleep 2
DISPLAY=:1 fluxbox &
sleep 2

# === LANCEMENT DU SERVEUR VNC ===
echo "[6/7] Lancement de x11vnc"
DISPLAY=:1 x11vnc -nopw -forever -shared -rfbport 5900 -bg

# === LANCEMENT DE noVNC ===
echo "[7/7] Lancement de noVNC sur :6080"
cd ~
git clone https://github.com/novnc/noVNC.git /opt/novnc &>/dev/null || true
/opt/novnc/utils/novnc_proxy --vnc localhost:5900 --listen 6080 &>/dev/null &

# === LANCEMENT DE FIREFOX EN MODE STEALTH ===
echo "
[OK] Environnement opérationnel. Accède via navigateur :"
echo "   http://$(curl -s ipinfo.io/ip):6080/vnc.html"
echo "
Puis lance :"
echo "   DISPLAY=:1 python3 /root/stealth_agent.py"
