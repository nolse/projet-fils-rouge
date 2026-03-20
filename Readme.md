# Projet Fil Rouge — IC Group DevOps

## Prérequis
- Terraform >= 1.4
- Ansible >= 2.12
- AWS CLI configuré (`aws configure`)
- Clé SSH `projet-fil-rouge-key.pem` dans `~/.ssh/`
- jq installé (`sudo apt install jq`)

## Déploiement complet

### 1. Déployer l'infrastructure AWS
```bash
cd ~/cursus-devops/projet_fil_rouge_infra/app
terraform init
terraform apply
```

### 2. Générer l'inventaire Ansible
```bash
cd ~/cursus-devops/projet-fils-rouge
bash inventaire/generate_inventory.sh
```

### 3. Installer les collections Ansible
```bash
ansible-galaxy collection install -r requirements.yml
```

### 4. Lancer le déploiement
```bash
ansible-playbook -i inventaire/hosts.yml playbook.yml
```

## Accès aux applications
| Application | URL |
|---|---|
| ic-webapp | http://<webapp_ip>:80 |
| pgAdmin | http://<webapp_ip>:5050 |
| Odoo | http://<odoo_ip>:8069 |
| Jenkins | http://<jenkins_ip>:8080 |

## Fin de session — destruction de l'infra
```bash
cd ~/cursus-devops/projet_fil_rouge_infra/app
terraform destroy
```
