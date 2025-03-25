#!/bin/bash

# ────────────── 🌐 CONFIG ──────────────
PROJECT_NAME="selenium_project"
GIT_REPO="https://github.com/pascalseppey/data.git"
GIT_FOLDER="data"
INSTALL_SCRIPT="check_and_setup.sh"
AGENT_SCRIPT="final_white_ghost_agent_terminal.py"
VENV_ACTIVATE=".venv/bin/activate"

# ────────────── 📁 1. Création du dossier projet ──────────────
echo "📁 Préparation du dossier $PROJECT_NAME..."

if [ ! -d "$HOME/$PROJECT_NAME" ]; then
    mkdir -p "$HOME/$PROJECT_NAME"
    echo "✅ Dossier créé : $HOME/$PROJECT_NAME"
else
    echo "✅ Dossier déjà présent : $HOME/$PROJECT_NAME"
fi

cd "$HOME/$PROJECT_NAME" || exit 1

# ────────────── 🧬 2. Cloner le dépôt si nécessaire ──────────────
if [ ! -d "$GIT_FOLDER" ]; then
    echo "🔄 Clonage du dépôt Git..."
    git clone "$GIT_REPO"
else
    echo "🔁 Mise à jour du dépôt Git..."
    cd "$GIT_FOLDER" && git pull && cd ..
fi

# ────────────── 🛠️ 3. Lancer le script d'installation ──────────────
echo "⚙️ Lancement de l'installation..."
chmod +x "$GIT_FOLDER/$INSTALL_SCRIPT"
bash "$GIT_FOLDER/$INSTALL_SCRIPT"

# ────────────── 🧪 4. Activation de l’environnement ──────────────
if [ -f "$VENV_ACTIVATE" ]; then
    echo "🐍 Activation de l’environnement virtuel..."
    source "$VENV_ACTIVATE"
else
    echo "❌ Erreur : environnement virtuel non trouvé. Abandon."
    exit 1
fi

# ────────────── 🚀 5. Lancement de l’agent ──────────────
echo "🚀 Lancement de l'agent terminal..."
python "$GIT_FOLDER/$AGENT_SCRIPT"
