#!/bin/bash

USE_FILE=false
PROXY_FILE=~/iproyal-proxies.txt

HOST="geo.iproyal.com"
PORT="12321"
USER="Yz3XQbz7vR2z3qmo"
PASS="rUwiPZvJ8YF5tR0b_country-ch"

TEST_URL="https://ipinfo.io/json"
LOG_FILE="ip_log.txt"

now=$(date "+%Y-%m-%d %H:%M:%S")

echo -e "\n[$now] Lancement du test..."

if $USE_FILE; then
  if [[ ! -f "$PROXY_FILE" ]]; then
    echo "Fichier $PROXY_FILE introuvable."
    exit 1
  fi
  LINE=$(head -n 1 "$PROXY_FILE")
  HOST=$(echo "$LINE" | cut -d':' -f1)
  PORT=$(echo "$LINE" | cut -d':' -f2)
  USER=$(echo "$LINE" | cut -d':' -f3)
  PASS=$(echo "$LINE" | cut -d':' -f4)
fi

PROXY="$HOST:$PORT"
AUTH="$USER:$PASS"

echo "Proxy utilisé : $USER@$HOST:$PORT"

RESPONSE=$(curl -s -x "http://$PROXY" -U "$AUTH" -w "\nHTTP_STATUS:%{http_code}" --connect-timeout 10 "$TEST_URL")

STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS" | cut -d':' -f2)
BODY=$(echo "$RESPONSE" | grep -v "HTTP_STATUS")

echo "Réponse :"
echo "$BODY"
echo "Code HTTP : $STATUS"

echo -e "[$now] $USER @ $HOST:$PORT => HTTP $STATUS\n$BODY\n" >> "$LOG_FILE"

if [[ "$STATUS" == "407" ]]; then
  echo "Erreur 407 : Authentification proxy incorrecte"
  exit 1
elif [[ "$STATUS" == "403" ]]; then
  echo "Erreur 403 : Accès refusé"
  exit 1
elif [[ "$STATUS" == "000" ]]; then
  echo "Timeout ou réponse vide. Proxy inaccessible ?"
  exit 1
else
  echo "Connexion réussie avec IP proxy"
fi
