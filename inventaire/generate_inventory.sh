#!/bin/bash
# ============================================================
# generate_inventory.sh
# Génère automatiquement l'inventaire Ansible (hosts.yml)
# en lisant les outputs Terraform (IPs publiques des serveurs)
# Utilisation : bash inventaire/generate_inventory.sh
# ============================================================

# Répertoire du script (pour chemins relatifs)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Répertoire Terraform à interroger
TERRAFORM_DIR="$HOME/cursus-devops/projet_fil_rouge_infra/app"

# Fichier de sortie inventaire Ansible
OUTPUT_FILE="$SCRIPT_DIR/hosts.yml"

# Clé SSH utilisée pour se connecter aux serveurs AWS
SSH_KEY="$HOME/.ssh/projet-fil-rouge-key.pem"

# Utilisateur SSH par défaut sur Ubuntu AWS
SSH_USER="ubuntu"

echo "��� Lecture des outputs Terraform depuis : $TERRAFORM_DIR"

# Récupérer les IPs au format JSON depuis le state Terraform
cd "$TERRAFORM_DIR" || { echo "❌ Dossier Terraform introuvable"; exit 1; }
TF_OUTPUT=$(terraform output -json public_ips 2>/dev/null)

# Vérifier que l'output n'est pas vide (infra déployée ?)
if [ -z "$TF_OUTPUT" ] || [ "$TF_OUTPUT" = "null" ]; then
  echo "❌ Aucun output Terraform trouvé."
  echo "   → Lance d'abord : terraform apply"
  exit 1
fi

# Extraire les IPs avec jq
JENKINS_IP=$(echo "$TF_OUTPUT" | jq -r '.jenkins')
WEBAPP_IP=$(echo "$TF_OUTPUT"  | jq -r '.webapp')
ODOO_IP=$(echo "$TF_OUTPUT"    | jq -r '.odoo')

echo "✅ IPs récupérées :"
echo "   jenkins : $JENKINS_IP"
echo "   webapp  : $WEBAPP_IP"
echo "   odoo    : $ODOO_IP"

# Générer le fichier hosts.yml
cat > "$OUTPUT_FILE" << YAML
---
# ============================================================
# Inventaire Ansible — généré automatiquement
# Source : terraform output public_ips
# Ne pas modifier manuellement, relancer generate_inventory.sh
# ============================================================

all:
  vars:
    # Clé SSH et utilisateur communs à tous les serveurs
    ansible_user: $SSH_USER
    ansible_ssh_private_key_file: $SSH_KEY
    ansible_ssh_common_args: '-o StrictHostKeyChecking=no'

  children:
    # Serveur Jenkins — CI/CD
    jenkins:
      hosts:
        jenkins_server:
          ansible_host: $JENKINS_IP

    # Serveur Webapp — site vitrine + pgAdmin
    webapp:
      hosts:
        webapp_server:
          ansible_host: $WEBAPP_IP

    # Serveur Odoo — ERP + PostgreSQL
    odoo:
      hosts:
        odoo_server:
          ansible_host: $ODOO_IP
YAML

echo "✅ Inventaire généré : $OUTPUT_FILE"
