# Projet Fil Rouge — IC Group DevOps

Deploiement complet d'une infrastructure DevOps en 3 parties :
conteneurisation, CI/CD et orchestration Kubernetes.

## Stack technique

- **Docker** — conteneurisation des applications
- **Terraform** — provisioning infrastructure AWS
- **Ansible** — deploiement et configuration des serveurs
- **Jenkins** — pipeline CI/CD
- **Kubernetes (Minikube)** — orchestration locale

## Applications deployees

| Application | Image | Description |
|---|---|---|
| ic-webapp | alphabalde/ic-webapp:1.0 | Site vitrine IC Group |
| Odoo | odoo:13.0 | ERP metier |
| PostgreSQL | postgres:13 | Base de donnees Odoo |
| pgAdmin | dpage/pgadmin4 | Interface admin BDD |
| Jenkins | jenkins/jenkins:lts | Pipeline CI/CD |

---

## Partie 1 — Conteneurisation Docker

Construction et publication de l'image ic-webapp.

```bash
docker build -t alphabalde/ic-webapp:1.0 .
docker push alphabalde/ic-webapp:1.0
```

## Partie 2 — CI/CD Jenkins + Ansible

Provisioning AWS via Terraform, deploiement via Ansible.

```bash
# 1. Provisioning infrastructure
cd projet_fil_rouge_infra/app && terraform apply

# 2. Export des IPs
terraform output -json public_ips > inventaire/terraform_ips.json

# 3. Deploiement Ansible (depuis WSL)
bash inventaire/generate_inventory.sh
ansible-playbook -i inventaire/hosts.yml playbook.yml -v

# 4. Fin de session
terraform destroy
```

**Acces :**
- Jenkins  : `http://<jenkins_ip>:8080`
- ic-webapp : `http://<webapp_ip>`
- pgAdmin  : `http://<webapp_ip>:5050`
- Odoo     : `http://<odoo_ip>:8069`

## Partie 3 — Kubernetes (Minikube)

Deploiement de toutes les applications dans un cluster Kubernetes local.

![Architecture Kubernetes](kubernetes/architecture.svg)

```bash
# 1. Demarrer le cluster
minikube start --driver=docker

# 2. Deployer toutes les ressources
bash kubernetes/commandes_utils.sh deploy

# 3. Ouvrir les tunnels (Windows)
bash kubernetes/commandes_utils.sh open

# 4. Mettre a jour les URLs vitrine avec les ports tunnels
bash kubernetes/commandes_utils.sh update-urls PORT_WEBAPP PORT_ODOO PORT_PGADMIN

# 5. Fin de session
minikube stop
```

**Acces (ports variables a chaque session) :**
- ic-webapp : `http://127.0.0.1:PORT`
- Odoo      : `http://127.0.0.1:PORT`
- pgAdmin   : `http://127.0.0.1:PORT`

**Credentials :**
- Odoo    : `admin` / `admin`
- pgAdmin : `admin@icgroup.fr` / `pgadmin_password`

Pour plus de details sur la Partie 3 : [kubernetes/README.md](kubernetes/README.md)

---

## Structure du projet

```
projet-fils-rouge/
├── Dockerfile                  # Image ic-webapp
├── releases.txt                # Version + URLs Odoo/pgAdmin
├── Jenkinsfile                 # Pipeline CI/CD
├── playbook.yml                # Playbook Ansible principal
├── ansible.cfg
├── requirements.yml
├── roles/
│   ├── odoo_role/
│   ├── pgadmin_role/
│   ├── webapp_role/
│   └── jenkins_role/
├── inventaire/
│   ├── generate_inventory.sh
│   └── hosts.yml.example
└── kubernetes/
    ├── namespace.yml
    ├── secrets.yml
    ├── commandes_utils.sh
    ├── architecture.svg
    ├── README.md
    ├── postgres/
    ├── odoo/
    ├── pgadmin/
    └── webapp/
```

## Auteur

Balde — Formation DevOps
