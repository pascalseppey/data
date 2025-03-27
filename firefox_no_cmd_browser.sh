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

# === TROUVER UN DISPLAY DISPONIBLE ===
DISPLAY_NUM=1
while [ -e "/tmp/.X${DISPLAY_NUM}-lock" ]; do
  DISPLAY_NUM=$((DISPLAY_NUM + 1))
done

# === INSTALLATION DES DÉPENDANCES ===
echo "[1/8] Installation des outils..."
apt update && apt install -y firefox x11vnc xvfb fluxbox curl unzip jq wget python3 python3-pip setxkbmap
pip3 install --break-system-packages selenium webdriver-manager fake-useragent

# === TÉLÉCHARGEMENT FOXYPROXY ===
echo "[2/8] Téléchargement de FoxyProxy"
curl -sL "$EXT_URL" -o "$EXT_FILE"

# === CRÉATION DU PROFIL FIREFOX ===
echo "[3/8] Préparation du profil Firefox : $PROFILE_NAME"
mkdir -p "$PROFILE_DIR/extensions"
unzip -q "$EXT_FILE" -d /tmp/foxyproxy_extract
FOXY_ID=$(jq -r '.applications.gecko.id' /tmp/foxyproxy_extract/manifest.json)
mv "$EXT_FILE" "$PROFILE_DIR/extensions/$FOXY_ID.xpi"
rm -rf /tmp/foxyproxy_extract

# === GÉNÉRATION DU SCRIPT SELENIUM ===
echo "[4/8] Génération du script Python Selenium"
cat > /root/stealth_agent.py <<EOF
from selenium import webdriver
from selenium.webdriver.firefox.options import Options
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

options.set_preference("browser.startup.homepage", "https://www.whatismybrowser.com/")
options.set_preference("startup.homepage_welcome_url.additional", "https://browserleaks.com/ip")

options.set_preference("app.normandy.first_run", False)
options.set_preference("toolkit.telemetry.reportingpolicy.firstRun", False)
options.set_preference("browser.shell.checkDefaultBrowser", False)

options.set_preference("dom.webdriver.enabled", False)
options.set_preference("useAutomationExtension", False)

print("[INFO] Lancement de Firefox avec proxy et user-agent personnalisé...")
driver = webdriver.Firefox(options=options)
driver.set_window_size(1280, 720)

sites = [
    "https://www.whatismybrowser.com/",
    "https://browserleaks.com/ip",
    "https://whoer.net"
]

for site in sites:
    print(f"[INFO] Ouverture : {site}")
    driver.get(site)
    time.sleep(10)

input("\n[OK] Contrôle manuel ouvert. Appuie sur [Entrée] pour quitter...\n")
driver.quit()
EOF

# === LANCEMENT D'UN ENVIRONNEMENT GRAPHIQUE ===
echo "[5/8] Lancement de Xvfb et Fluxbox"
killall -q Xvfb fluxbox firefox x11vnc || true
Xvfb :$DISPLAY_NUM -screen 0 1280x720x24 &
sleep 2
setxkbmap ch mac -display :$DISPLAY_NUM
DISPLAY=:$DISPLAY_NUM fluxbox &
sleep 2

# === RACCOURCI BUREAU POUR FIREFOX ===
echo "[6/8] Ajout icône Firefox au menu"
echo -e '[exec] (Firefox) {firefox --no-remote --profile '"$PROFILE_DIR"'}' >> ~/.fluxbox/menu

# === LANCEMENT DU SERVEUR VNC ===
echo "[7/8] Lancement de x11vnc"
DISPLAY=:$DISPLAY_NUM x11vnc -nopw -forever -shared -rfbport 5900 -bg

# === LANCEMENT DE noVNC ===
echo "[8/8] Lancement de noVNC sur :6080"
git clone https://github.com/novnc/noVNC.git /opt/novnc &>/dev/null || true
/opt/novnc/utils/novnc_proxy --vnc localhost:5900 --listen 6080 &>/dev/null &

# === AFFICHAGE FINAL ===
echo "\n[OK] Environnement opérationnel. Connecte-toi via :"
echo "   http://\$(curl -s ipinfo.io/ip):6080/vnc.html"
echo "\nPuis, dans le terminal, lance :"
echo "   DISPLAY=:$DISPLAY_NUM python3 /root/stealth_agent.py"
