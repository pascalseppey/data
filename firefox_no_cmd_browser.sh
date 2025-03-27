#!/bin/bash

# === Nettoyage précédent ===
killall -q firefox Xvfb x11vnc fluxbox novnc_proxy || true

# === Variables ===
FIREFOX_DIR="/opt/firefox"
GECKODRIVER_VERSION="v0.36.0"
DISPLAY_NUM=1

# === 1. Installer Firefox (binaire officiel) ===
echo "[1/6] Installation manuelle de Firefox"
rm -rf "$FIREFOX_DIR"
mkdir -p "$FIREFOX_DIR"
wget -qO /tmp/firefox.tar.bz2 "https://download.mozilla.org/?product=firefox-latest&os=linux64&lang=fr"
tar -xjf /tmp/firefox.tar.bz2 -C "$FIREFOX_DIR" --strip-components=1
ln -sf "$FIREFOX_DIR/firefox" /usr/local/bin/firefox

# === 2. Installer Geckodriver (v0.36.0 recommandé pour Firefox 136) ===
echo "[2/6] Installation Geckodriver $GECKODRIVER_VERSION"
wget -qO /tmp/geckodriver.tar.gz "https://github.com/mozilla/geckodriver/releases/download/${GECKODRIVER_VERSION}/geckodriver-${GECKODRIVER_VERSION}-linux64.tar.gz"
tar -xzf /tmp/geckodriver.tar.gz -C /usr/local/bin
chmod +x /usr/local/bin/geckodriver

# === 3. Vérif ===
echo "[INFO] Versions installées :"
firefox --version
geckodriver --version

# === 4. Lancer environnement graphique ===
echo "[3/6] Lancement Xvfb + fluxbox + x11vnc + noVNC"
Xvfb :$DISPLAY_NUM -screen 0 1280x720x24 &>/dev/null &
sleep 2
setxkbmap ch mac -display :$DISPLAY_NUM
DISPLAY=:$DISPLAY_NUM fluxbox &>/dev/null &
sleep 1
DISPLAY=:$DISPLAY_NUM x11vnc -nopw -forever -shared -rfbport 5900 -bg &>/dev/null
/opt/novnc/utils/novnc_proxy --vnc localhost:5900 --listen 6080 &>/dev/null &

# === 5. Créer script de test Firefox avec proxy ===
echo "[4/6] Création de /root/stealth_test_firefox.py"
cat > /root/stealth_test_firefox.py <<EOF
from selenium import webdriver
from selenium.webdriver.firefox.options import Options
from fake_useragent import UserAgent
import time

options = Options()
ua = UserAgent()
user_agent = ua.random
options.set_preference("general.useragent.override", user_agent)
options.set_preference("network.proxy.type", 1)
options.set_preference("network.proxy.http", "geo.iproyal.com")
options.set_preference("network.proxy.http_port", 12321)
options.set_preference("network.proxy.ssl", "geo.iproyal.com")
options.set_preference("network.proxy.ssl_port", 12321)
options.set_preference("network.proxy.socks_remote_dns", True)
options.set_preference("signon.autologin.proxy", True)
options.set_preference("dom.webdriver.enabled", False)
options.set_preference("useAutomationExtension", False)
options.set_preference("media.peerconnection.enabled", False)
options.set_preference("privacy.resistFingerprinting", True)
options.set_preference("browser.shell.checkDefaultBrowser", False)

print("[INFO] Lancement de Firefox stealth...")
driver = webdriver.Firefox(options=options)
driver.set_window_size(1280, 720)
driver.get("https://whatismybrowser.com/")
time.sleep(10)
driver.quit()
EOF

# === 6. Info finale ===
echo "[5/6] Accès distant :"
echo "   http://$(curl -s ipinfo.io/ip):6080/vnc.html"
echo "[6/6] Pour lancer Firefox avec proxy et fingerprint :"
echo "   DISPLAY=:$DISPLAY_NUM python3 /root/stealth_test_firefox.py"
