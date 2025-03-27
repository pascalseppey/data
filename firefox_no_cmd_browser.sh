#!/bin/bash

# === INSTALLATION DES OUTILS NÉCESSAIRES ===
sudo apt update
sudo apt install -y python3 python3-pip tightvncserver novnc fluxbox xterm
pip3 install virtualenv

# === INSTALLATION DE GOOGLE CHROME SI ABSENT ===
if ! command -v google-chrome &> /dev/null; then
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo apt install -y ./google-chrome-stable_current_amd64.deb
fi

# === CONFIGURATION DU PROXY IPRoyal ===
PROXY_HOST="geo.iproyal.com"
PROXY_PORT="12321"
PROXY_USER="Yz3XQbz7vR2z3qmo"
PROXY_PASS="rUwiPZvJ8YF5tR0b_country-ch"
SESSION_ID="agent$RANDOM"

# === PRÉPARATION D’UN ENVIRONNEMENT PYTHON ISOLÉ ===
mkdir -p ~/agent_selenium
cd ~/agent_selenium
virtualenv venv
source venv/bin/activate
pip install undetected-chromedriver fake-useragent

# === SCRIPT PYTHON POUR LANCER LE NAVIGATEUR ===
cat <<EOF > run_agent.py
import undetected_chromedriver as uc
from selenium.webdriver.common.by import By
from fake_useragent import UserAgent
import time

proxy = "${PROXY_USER}-session-${SESSION_ID}:${PROXY_PASS}@${PROXY_HOST}:${PROXY_PORT}"
ua = UserAgent()

options = uc.ChromeOptions()
options.add_argument(f"--proxy-server=http://{proxy}")
options.add_argument(f"user-agent={ua.random}")
options.add_argument("--disable-blink-features=AutomationControlled")
options.add_argument("--start-maximized")
options.add_argument("--no-sandbox")
options.add_argument("--disable-dev-shm-usage")

driver = uc.Chrome(options=options)
driver.get("https://browserleaks.com/")
time.sleep(20)
driver.quit()
EOF

# === LANCEMENT DU SERVEUR VNC + FLUXBOX + CHROME HEAD ===
tightvncserver -kill :1
tightvncserver :1 -geometry 1280x800 -depth 24 -localhost no
export DISPLAY=:1
fluxbox &

# === LANCEMENT DE SELENIUM DANS LE TERMINAL GRAPHIQUE ===
xterm -e "source ~/agent_selenium/venv/bin/activate && python3 ~/agent_selenium/run_agent.py" &

# === LANCEMENT DE NOVNC POUR ACCÈS DISTANT ===
novnc --vnc localhost:5901
