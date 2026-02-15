#!/usr/bin/env bash
#--------------------------------------------------------------------------------
#       Nom     : hue_set_wakeup.sh
#       Version : 1.00
#       Date    : 2026/02/15
#       Langage : bash
#       Descrip : Modifie l'heure d'une automatisation Philips Hue depuis HA
#       Auteur  : Fred BRACHOT
#--------------------------------------------------------------------------------
#       Inputs  : Nom de l'automatisation, heure pour l'automatisation, minutes pour l'automatisation, état cible de l'automatisation (enabled|disabled)
#       Outputs : Mise à jour de l'automatisation Hue
#       Exemple : hue_set_wakeup.sh "Nom de l'automatisation" [HH] [MM] [enabled|disabled]
#--------------------------------------------------------------------------------
# Code d'erreur : 0 : Sortie "normale"
#                 1 : Nom de l'automatisation manquant
#                 2 : Automation Hue introuvable
#--------------------------------------------------------------------------------
# Revision 1.00  2026/02/15  F. BRACHOT
# * Première version publiée
#--------------------------------------------------------------------------------

AUTOMATION_NAME="$1"
HOUR="$2"
MINUTE="$3"
STATE="$4"

# ====== CONFIG HUE ======
FIC_CONFIG='/config/.storage/core.config_entries'
CONF_HUE=$(jq '.data.entries[] | select(.domain=="hue")' $FIC_CONFIG)
HUE_ADDR=$(echo $CONF_HUE |jq -r .data.host)
HUE_KEY=$(echo $CONF_HUE |jq -r .data.api_key)

# ====== VALEURS PAR DÉFAUT (par sécurité) ======
DEFAULT_HOUR=7
DEFAULT_MINUTE=25
DEFAULT_STATE="enabled"

# ====== VALIDATION PARAMÈTRES ======
if [[ -z "$AUTOMATION_NAME" ]]; then
  echo "Nom de l'automatisation manquant"
  exit 1
fi

if ! [[ "$HOUR" =~ ^[0-9]+$ ]] || [[ "$HOUR" -gt 23 ]]; then
  HOUR="$DEFAULT_HOUR"
fi

if ! [[ "$MINUTE" =~ ^[0-9]+$ ]] || [[ "$MINUTE" -gt 59 ]]; then
  MINUTE="$DEFAULT_MINUTE"
fi

if [[ "$STATE" != "enabled" && "$STATE" != "disabled" ]]; then
  STATE="$DEFAULT_STATE"
fi

#echo "Hue automation: $AUTOMATION_NAME → $STATE @ $HOUR:$MINUTE"

# ====== RÉCUPÉRATION AUTOMATION ======
AUTOMATION=$(curl --silent --fail -k --noproxy '*' \
  --header "hue-application-key: $HUE_KEY" \
  "https://$HUE_ADDR/clip/v2/resource/behavior_instance" \
  | jq '.data[] | select(.metadata.name=="'"$AUTOMATION_NAME"'")')

AUTOMATION_ID=$(echo "$AUTOMATION" | jq -r .id)

if [[ -z "$AUTOMATION_ID" || "$AUTOMATION_ID" == "null" ]]; then
  echo "Automation Hue introuvable"
  exit 2
fi

# ====== MODIFICATION CONFIGURATION ======
CONF="{\"configuration\": $(echo "$AUTOMATION" | jq '
  .configuration
  | .when.time_point.time.hour = '"$HOUR"'
  | .when.time_point.time.minute = '"$MINUTE"'
')}"

if [[ "$STATE" == "disabled" ]]; then
  CONF=$(echo "$CONF" | jq '.enabled = false')
else
  CONF=$(echo "$CONF" | jq '.enabled = true')
fi

# ====== MISE A JOUR DE L'AUTOMATISATION HUE ======
curl --silent --fail -k --noproxy '*' \
  --header "hue-application-key: $HUE_KEY" \
  --request PUT \
  --data "$CONF" \
  "https://$HUE_ADDR/clip/v2/resource/behavior_instance/$AUTOMATION_ID"

exit 0