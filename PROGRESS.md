# Projet Fil Rouge — Avancement

## Stack
- Terraform 1.14.5
- AWS us-east-1
- Backend S3 : terraform-backend-balde
- Repo infra : https://github.com/nolse/projet_fil_rouge_infra

## IPs (terraform output) — régénérer après chaque apply
- jenkins : dynamique (bash inventaire/generate_inventory.sh)
- odoo    : dynamique
- webapp  : dynamique

## Étapes
- [x] Prérequis locaux
- [x] Bucket S3 + versioning
- [x] Git initialisé
- [x] Modules Terraform (security_group, ec2, ebs, eip)
- [x] terraform apply — 3 VMs opérationnelles
- [x] SSH OK sur les 3 serveurs
- [x] Partie 1 : Conteneurisation app vitrine (Docker)
      - [x] ic-webapp:1.0 buildée et pushée → alphabalde/ic-webapp:1.0
      - [x] odoo/docker-compose.yml
      - [x] pgadmin/docker-compose.yml + servers.json
      - [x] jenkins-tools/ (Dockerfile + docker-compose + conf + scripts)
- [ ] Partie 2 : Pipeline CI/CD Jenkins + Ansible
      - [x] roles/odoo_role    — Odoo 13 + PostgreSQL
      - [x] roles/pgadmin_role — pgAdmin4
      - [x] roles/webapp_role  — ic-webapp + injection ODOO_URL/PGADMIN_URL
      - [x] roles/jenkins_role — Jenkins (sadofrazer/jenkins)
      - [x] inventaire/generate_inventory.sh — inventaire dynamique Terraform→Ansible
      - [x] ansible.cfg
      - [x] playbook.yml
      - [x] requirements.yml
      - [x] README.md
      - [ ] Jenkinsfile — pipeline CI/CD
- [ ] Partie 3 : Kubernetes
