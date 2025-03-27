#!/bin/bash

###################################################################
# 1) Installation / Mise à jour des dépendances de base
###################################################################
sudo apt-get update

# Installer python3-venv pour créer un environnement virtuel isolé
sudo apt-get install -y python3-venv

# Installer quelques paquets nécessaires
# - tightvncserver : serveur VNC
# - novnc : pour l'accès VNC via navigateur
# - fluxbox : window manager léger
# - xterm : terminal graphique
# - wget, gdebi-core : pour installer Chrome via .deb
sudo apt-get install -y tightvncserver novnc fluxbox xterm wget gdebi-core

###################################################################
# 2) Installation de Google Chrome (si non présent)
###################################################################
if ! command -v google-chrome &> /dev/null; then
    echo "[INFO] Google Chrome non détecté, installation..."
    wget -O /tmp/google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo gdebi -n /tmp/google-chrome-stable_current_amd64.deb
    rm -f /tmp/google-chrome-stable_current_amd64.deb
fi

###################################################################
# 3) Configuration du proxy IP Royale
###################################################################
# Mettez ici vos identifiants et infos de connexion IPRoyal
PROXY_HOST="geo.iproyal.com"
PROXY_PORT="12321"
PROXY_USER="Yz3XQbz7vR2z3qmo"
PROXY_PASS="rUwiPZvJ8YF5tR0b_country-ch"
SESSION_ID="agent$RANDOM"

###################################################################
# 4) Prépare un dossier de travail + environnement virtuel Python
###################################################################
mkdir -p ~/agent_selenium
cd ~/agent_selenium

# Crée et active l'environnement virtuel
python3 -m venv venv
# Pour contourner le « externally-managed-environment », on ajoute --break-system-packages
source venv/bin/activate

# Installe les bibliothèques nécessaires dans l'environnement virtuel
pip install --break-system-packages undetected-chromedriver fake-useragent

###################################################################
# 5) Crée un script Python Selenium pour lancer Chrome avec fingerprint caché
###################################################################
cat <<EOF > run_agent.py
import undetected_chromedriver as uc
from selenium.webdriver.common.by import By
from fake_useragent import UserAgent
import time

# Prépare le proxy IPRoyal + user-agent randomisé
proxy = f"{${PROXY_USER}-session-${SESSION_ID}:{PROXY_PASS}@{PROXY_HOST}:{PROXY_PORT}}"
ua = UserAgent()

options = uc.ChromeOptions()
options.add_argument(f"--proxy-server=http://{proxy}")
options.add_argument(f"user-agent={ua.random}")
options.add_argument("--disable-blink-features=AutomationControlled")
options.add_argument("--start-maximized")
options.add_argument("--no-sandbox")
options.add_argument("--disable-dev-shm-usage")

# Lance Chrome
driver = uc.Chrome(options=options)

try:
    # Vérification sur un site qui affiche l'IP, fingerprint etc.
    driver.get("https://browserleaks.com/")
    time.sleep(20)  # Laisser le temps d'observer
finally:
    driver.quit()
EOF

###################################################################
# 6) Configuration / Démarrage du serveur VNC
###################################################################
# NOTE : la première fois, VNC demandera la création d'un mot de passe.
# On peut « forcer » un pass par script, mais veillez à ce qu'il fasse
# au moins 6 caractères pour éviter l'erreur "Password too short".

mkdir -p ~/.vnc

# Mettez un mot de passe d'au moins 6 caractères
PASS="vncpassw"
# On écrit deux fois le password (pour confirmation)
echo -e "${PASS}\n${PASS}\n" | tightvncpasswd

# Relance le serveur :1
tightvncserver -kill :1 2>/dev/null || true
tightvncserver :1 -geometry 1280x800 -depth 24 -localhost no

###################################################################
# 7) Lancement de fluxbox et Selenium dans xterm (sur DISPLAY :1)
###################################################################
export DISPLAY=:1

# Lance fluxbox (window manager)
fluxbox &

# Lance xterm qui exécute notre script Selenium
# (ainsi, on verra la fenêtre Chrome s'ouvrir virtuellement)
xterm -e "cd ~/agent_selenium && source venv/bin/activate && python3 run_agent.py" &

###################################################################
# 8) Lancement de noVNC pour accéder au bureau à distance
###################################################################
# Selon l’install, la commande peut être différente.
# Sur Debian/Ubuntu, souvent on utilise : /usr/share/novnc/utils/launch.sh
# On met en arrière-plan (avec &) OU on le laisse en front.
###################################################################
if [ -x /usr/bin/novnc ]; then
    # Si la commande 'novnc' existe
    novnc --vnc localhost:5901
elif [ -f /usr/share/novnc/utils/launch.sh ]; then
    # Sinon, on lance via le script de noVNC
    cd /usr/share/novnc
    ./utils/launch.sh --vnc localhost:5901
else
    echo "ERREUR : Impossible de trouver la commande noVNC."
    echo "Essayez de localiser l'exécutable avec : 'which novnc' ou 'locate novnc'"
    exit 1
fi
