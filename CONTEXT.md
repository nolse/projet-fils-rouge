# Contexte Projet Fil Rouge — IC Group DevOps
# À coller en début de session Claude pour reprendre sans perte de contexte

## Stack technique
- Terraform 1.14.5 | AWS us-east-1 | Backend S3 : terraform-backend-balde
- Ansible >= 2.12 | Collection community.docker
- Docker | Images : alphabalde/ic-webapp:1.0, sadofrazer/jenkins, odoo:13.0, dpage/pgadmin4
- Repo infra    : https://github.com/nolse/projet_fil_rouge_infra
- Repo ansible  : ~/cursus-devops/projet-fils-rouge

## Architecture serveurs AWS
| Serveur | Type | Ce qui tourne | Ports |
|---|---|---|---|
| jenkins | t3.medium | Jenkins (sadofrazer/jenkins) | 8080, 22000, 50000 |
| webapp  | t3.micro  | ic-webapp + pgAdmin | 80, 5050 |
| odoo    | t3.medium | Odoo 13 + PostgreSQL | 8069, 5432 |

## Structure Terraform
```
projet_fil_rouge_infra/app/
├── main.tf          # Backend S3 + provider + modules sg/ec2/eip
├── outputs.tf       # output public_ips (map jenkins/webapp/odoo)
├── variables.tf     # region, key_name, environment
└── terraform.tfvars # region=us-east-1 | key=projet-fil-rouge-key | env=prod

modules/ : security_group | ec2 | eip
Ports SG : 22, 80, 8080, 8069, 5050
```

## Structure Ansible
```
projet-fils-rouge/
├── ansible.cfg                        # Config globale Ansible
├── playbook.yml                       # Playbook principal (3 plays)
├── requirements.yml                   # community.docker
├── README.md                          # Guide de reproduction
├── inventaire/
│   ├── generate_inventory.sh          # Lit terraform output → génère hosts.yml
│   └── hosts.yml.example              # Modèle inventaire (hosts.yml ignoré par git)
└── roles/
    ├── odoo_role/                     # Odoo 13 + PostgreSQL via docker-compose
    ├── pgadmin_role/                  # pgAdmin4 + servers.json préconfiguré
    ├── webapp_role/                   # ic-webapp + ODOO_URL/PGADMIN_URL injectées
    └── jenkins_role/                  # Jenkins sadofrazer/jenkins
```

## Points importants
- IPs dynamiques → destroy/apply à chaque session → relancer generate_inventory.sh
- ic-webapp nécessite ODOO_URL et PGADMIN_URL (injectées depuis hostvars dans playbook.yml)
- pgadmin_db_host = IP du serveur odoo (injecté dynamiquement dans playbook.yml)
- Stratégie coûts : terraform destroy dès fin de session

## Commandes clés
```bash
# Déployer infra
cd ~/cursus-devops/projet_fil_rouge_infra/app && terraform apply

# Générer inventaire
cd ~/cursus-devops/projet-fils-rouge && bash inventaire/generate_inventory.sh

# Installer collections Ansible
ansible-galaxy collection install -r requirements.yml

# Déployer toutes les applications
ansible-playbook -i inventaire/hosts.yml playbook.yml

# Détruire infra (fin de session)
cd ~/cursus-devops/projet_fil_rouge_infra/app && terraform destroy
```

## Avancement
- [x] Partie 1 : Conteneurisation Docker
- [ ] Partie 2 : CI/CD Jenkins + Ansible → reste : Jenkinsfile
- [ ] Partie 3 : Kubernetes
