#!/bin/bash
# ============================================================
# reproduce_deploy.sh — Partie 2 : Deploiement Ansible
# A lancer depuis WSL apres reproduce_infra.sh
#
# Etapes :
#   1. Copie du repo depuis Windows vers WSL
#   2. Copie de la cle SSH
#   3. Installation des dependances Ansible
#   4. Generation de l'inventaire depuis terraform_ips.json
#   5. Attente disponibilite SSH des instances AWS
#   6. Deploiement via ansible-playbook
#
# Prerequis :
#   - reproduce_infra.sh execute avec succes
#   - terraform_ips.json present dans inventaire/
#
# Utilisation :
#   bash reproduce_deploy.sh
# ============================================================

set -e  # Arret immediat si une commande echoue

WIN_USER="balde"
WIN_REPO="/mnt/c/Users/${WIN_USER}/cursus-devops/projet-fils-rouge"
WIN_KEY="/mnt/c/Users/${WIN_USER}/cursus-devops/projet_fil_rouge_infra/.secrets/projet-fil-rouge-key.pem"
WSL_REPO="$HOME/projet-fils-rouge"
WSL_KEY="$HOME/projet-fil-rouge-key.pem"
SLEEP_SSH=90    # Secondes d'attente avant que SSH soit disponible sur AWS
SLEEP_PLAYS=20  # Secondes entre les plays Ansible

echo "============================================================"
echo " Reproduction Partie 2 — Deploiement Ansible"
echo "============================================================"

# --------------------------------------------------------
# Etape 1 : Copie du repo Windows → WSL
# --------------------------------------------------------
echo ""
echo "[1/5] Copie du repo vers WSL..."
rm -rf "$WSL_REPO"
cp -r "$WIN_REPO" "$WSL_REPO"
echo "✅ Repo copie : $WSL_REPO"

# --------------------------------------------------------
# Etape 2 : Copie et securisation de la cle SSH
# --------------------------------------------------------
echo ""
echo "[2/5] Copie de la cle SSH..."
cp "$WIN_KEY" "$WSL_KEY"
chmod 600 "$WSL_KEY"
echo "✅ Cle SSH prete : $WSL_KEY"

# --------------------------------------------------------
# Etape 3 : Installation des dependances Ansible
# --------------------------------------------------------
echo ""
echo "[3/5] Installation des dependances Ansible..."
cd "$WSL_REPO"
ansible-galaxy collection install community.docker --upgrade
echo "✅ Dependances installees"

# --------------------------------------------------------
# Etape 4 : Generation de l'inventaire Ansible
# --------------------------------------------------------
echo ""
echo "[4/5] Generation de l'inventaire Ansible..."
bash inventaire/generate_inventory.sh
echo "✅ Inventaire genere"

# --------------------------------------------------------
# Etape 5 : Attente disponibilite SSH
# Les instances AWS ont besoin de temps pour demarrer
# et accepter les connexions SSH apres terraform apply
# --------------------------------------------------------
echo ""
echo "[5/5] Attente disponibilite SSH des instances AWS..."
echo "      (${SLEEP_SSH}s — demarrage EC2 + cloud-init)"

for i in $(seq "$SLEEP_SSH" -10 10); do
    echo "      ... encore ${i}s"
    sleep 10
done

# --------------------------------------------------------
# Verification SSH avant de lancer Ansible
# --------------------------------------------------------
echo ""
echo "      Verification SSH..."
ansible all -i inventaire/hosts.yml -m ping --timeout=10 || {
    echo ""
    echo "⚠️  SSH pas encore pret, on attend 30s de plus..."
    sleep 30
    ansible all -i inventaire/hosts.yml -m ping --timeout=10 || {
        echo "❌ Instances SSH inaccessibles. Verifiez votre Security Group."
        exit 1
    }
}
echo "✅ Toutes les instances sont accessibles"

# --------------------------------------------------------
# Deploiement Ansible
# Les plays sont separes par des sleeps pour laisser
# chaque service demarrer avant le suivant
# --------------------------------------------------------
echo ""
echo "      Lancement du deploiement Ansible..."
echo ""

# Play 1 : Odoo + PostgreSQL
echo "--- Play 1 : Odoo + PostgreSQL ---"
ansible-playbook \
    -i inventaire/hosts.yml \
    --private-key="$WSL_KEY" \
    --limit odoo \
    playbook.yml -v

echo ""
echo "      Attente demarrage Odoo + PostgreSQL (${SLEEP_PLAYS}s)..."
sleep "$SLEEP_PLAYS"

# Play 2 : ic-webapp + pgAdmin
echo "--- Play 2 : ic-webapp + pgAdmin ---"
ansible-playbook \
    -i inventaire/hosts.yml \
    --private-key="$WSL_KEY" \
    --limit webapp \
    playbook.yml -v

echo ""
echo "      Attente demarrage ic-webapp + pgAdmin (${SLEEP_PLAYS}s)..."
sleep "$SLEEP_PLAYS"

# Play 3 : Jenkins
echo "--- Play 3 : Jenkins ---"
ansible-playbook \
    -i inventaire/hosts.yml \
    --private-key="$WSL_KEY" \
    --limit jenkins \
    playbook.yml -v

# --------------------------------------------------------
# Recapitulatif final
# --------------------------------------------------------
echo ""
echo "============================================================"
echo " Deploiement termine !"
echo "============================================================"

JENKINS_IP=$(jq -r '.jenkins' "$WSL_REPO/inventaire/terraform_ips.json")
WEBAPP_IP=$(jq  -r '.webapp'  "$WSL_REPO/inventaire/terraform_ips.json")
ODOO_IP=$(jq    -r '.odoo'    "$WSL_REPO/inventaire/terraform_ips.json")

echo ""
echo " Acces aux services :"
echo "   Jenkins  -> http://${JENKINS_IP}:8080"
echo "   ic-webapp -> http://${WEBAPP_IP}"
echo "   pgAdmin  -> http://${WEBAPP_IP}:5050"
echo "   Odoo     -> http://${ODOO_IP}:8069"
echo ""
echo " Fin de session :"
echo "   cd ~/cursus-devops/projet_fil_rouge_infra/app && terraform destroy"
echo "============================================================"
