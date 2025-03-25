#!/bin/bash

echo "🔍 Vérification et préparation de l’environnement..."

# Créer dossier projet
mkdir -p ~/selenium_project
cd ~/selenium_project || exit

# Installer dépendances système
apt update && apt install -y python3 python3-venv python3-pip unzip curl wget xterm fluxbox xvfb x11vnc

# Télécharger Google Chrome
if ! command -v google-chrome &> /dev/null; then
  echo "📦 Installation Google Chrome..."
  wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  apt install -y ./google-chrome-stable_current_amd64.deb
fi

# Installer chromedriver 134 (compatible avec Chrome stable 134)
echo "📦 Installation ChromeDriver 134..."
rm -f /usr/local/bin/chromedriver
wget https://storage.googleapis.com/chrome-for-testing-public/134.0.6998.165/linux64/chromedriver-linux64.zip
unzip -o chromedriver-linux64.zip
mv chromedriver-linux64/chromedriver /usr/local/bin/chromedriver
chmod +x /usr/local/bin/chromedriver

# Créer environnement virtuel Python
if [ ! -d ".venv" ]; then
  python3 -m venv .venv
fi
source .venv/bin/activate

# Mettre à jour pip et installer les bibliothèques
pip install --upgrade pip
pip install selenium fake-useragent requests

# Ajouter kernel Jupyter
python -m ipykernel install --user --name=venv --display-name "Python (venv)"

echo "✅ Environnement prêt. Tu peux maintenant lancer le script Python."
